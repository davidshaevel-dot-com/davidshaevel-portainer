#!/usr/bin/env bash
# Install Portainer Agent on the GKE cluster via kubectl manifest.
# The agent runs with a LoadBalancer so the AKS-hosted Portainer server can connect to it.
# Reference: https://docs.portainer.io/admin/environments/add/kubernetes/agent

source "$(dirname "$0")/../config.sh"
setup_logging "portainer-gke-agent-install"

# Ensure kubectl context is pointing to GKE.
CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || true)
if [[ "${CURRENT_CONTEXT}" != *"${GKE_CLUSTER_NAME}"* ]]; then
    echo "Switching kubectl context to GKE cluster..."
    gcloud container clusters get-credentials "${GKE_CLUSTER_NAME}" \
        --project="${GCP_PROJECT}" \
        --zone="${GKE_ZONE}"
fi

echo "Installing Portainer Agent on GKE cluster '${GKE_CLUSTER_NAME}'..."
echo ""

kubectl apply -f "${PORTAINER_AGENT_MANIFEST}"

# Restrict the LoadBalancer to accept traffic only from the AKS egress IP.
# GKE auto-creates firewall rules for LoadBalancer services that allow 0.0.0.0/0.
# Setting loadBalancerSourceRanges overrides that to only the AKS egress IP.
echo ""
echo "Getting AKS egress IP for LoadBalancer source restriction..."
AKS_EGRESS_ID=$(az aks show \
    --subscription "${SUBSCRIPTION}" \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${AKS_CLUSTER_NAME}" \
    --query "networkProfile.loadBalancerProfile.effectiveOutboundIPs[0].id" \
    --output tsv)
AKS_PUBLIC_IP=$(az network public-ip show --ids "${AKS_EGRESS_ID}" --query "ipAddress" --output tsv)

if [ -z "${AKS_PUBLIC_IP}" ]; then
    echo "Warning: Could not determine AKS egress IP. LoadBalancer will accept all traffic."
else
    echo "Restricting LoadBalancer to AKS egress IP: ${AKS_PUBLIC_IP}/32"
    kubectl patch svc portainer-agent -n portainer --type='merge' \
        -p "{\"spec\":{\"loadBalancerSourceRanges\":[\"${AKS_PUBLIC_IP}/32\"]}}"
fi

echo ""
echo "Waiting for agent pod to be ready..."
kubectl wait -n portainer --for=condition=ready pod -l app=portainer-agent --timeout=2m

echo ""
echo "Waiting for LoadBalancer external IP..."
if kubectl wait -n portainer --for=jsonpath='{.status.loadBalancer.ingress}' service/portainer-agent --timeout=3m; then
    AGENT_IP=$(kubectl get svc portainer-agent -n portainer -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo ""
    echo "Portainer Agent LoadBalancer IP: ${AGENT_IP}"
    echo ""
    echo "Next steps:"
    echo "  1. In the Portainer UI, go to Environments > Add Environment"
    echo "  2. Select 'Agent' and enter: ${AGENT_IP}:9001"
    echo "  3. Name it 'GKE'"
else
    echo "LoadBalancer IP not assigned after 3 minutes."
    echo "Run: kubectl get svc -n portainer -w"
fi
