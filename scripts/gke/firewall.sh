#!/usr/bin/env bash
# Create or update a GCP firewall rule to restrict Portainer Agent port 9001
# to the AKS cluster's outbound IP only.

source "$(dirname "$0")/../config.sh"
setup_logging "gke-firewall"

FIREWALL_RULE_NAME="allow-portainer-agent-from-aks"
AGENT_PORT="9001"

# Get AKS cluster outbound IP.
echo "Getting AKS cluster outbound IP..."
AKS_EGRESS_IP=$(az aks show \
    --subscription "${SUBSCRIPTION}" \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${AKS_CLUSTER_NAME}" \
    --query "networkProfile.loadBalancerProfile.effectiveOutboundIPs[0].id" \
    --output tsv)

if [ -z "${AKS_EGRESS_IP}" ]; then
    echo "Error: Could not determine AKS outbound IP resource ID."
    echo "Ensure the AKS cluster is running."
    exit 1
fi

# Resolve the public IP address from the resource ID.
AKS_PUBLIC_IP=$(az network public-ip show --ids "${AKS_EGRESS_IP}" --query "ipAddress" --output tsv)

if [ -z "${AKS_PUBLIC_IP}" ]; then
    echo "Error: Could not resolve AKS public IP from resource ID."
    exit 1
fi

echo "AKS egress IP: ${AKS_PUBLIC_IP}"

# Get the GKE cluster network tag (used by firewall rules to target nodes).
echo ""
echo "Getting GKE node network tag..."
GKE_NETWORK_TAG=$(gcloud compute instances list \
    --project="${GCP_PROJECT}" \
    --filter="name~^gke-${GKE_CLUSTER_NAME}" \
    --format="value(tags.items[0])" \
    --limit=1 2>/dev/null || true)

if [ -z "${GKE_NETWORK_TAG}" ]; then
    echo "Warning: Could not determine GKE node network tag."
    echo "Applying firewall rule to all instances in the project."
    TARGET_FLAG=""
else
    echo "GKE node tag: ${GKE_NETWORK_TAG}"
    TARGET_FLAG="--target-tags=${GKE_NETWORK_TAG}"
fi

# Create or update the firewall rule.
echo ""
echo "Configuring firewall rule '${FIREWALL_RULE_NAME}'..."
echo "  Allow TCP:${AGENT_PORT} from ${AKS_PUBLIC_IP}/32"
echo ""

if gcloud compute firewall-rules describe "${FIREWALL_RULE_NAME}" --project="${GCP_PROJECT}" >/dev/null 2>&1; then
    echo "Updating existing firewall rule..."
    gcloud compute firewall-rules update "${FIREWALL_RULE_NAME}" \
        --project="${GCP_PROJECT}" \
        --source-ranges="${AKS_PUBLIC_IP}/32" \
        --rules="tcp:${AGENT_PORT}" \
        ${TARGET_FLAG} \
        --quiet
else
    echo "Creating new firewall rule..."
    gcloud compute firewall-rules create "${FIREWALL_RULE_NAME}" \
        --project="${GCP_PROJECT}" \
        --direction=INGRESS \
        --priority=1000 \
        --network=default \
        --action=ALLOW \
        --rules="tcp:${AGENT_PORT}" \
        --source-ranges="${AKS_PUBLIC_IP}/32" \
        ${TARGET_FLAG} \
        --description="Allow Portainer Agent (port ${AGENT_PORT}) from AKS cluster egress IP only"
fi

echo ""
echo "Firewall rule '${FIREWALL_RULE_NAME}' configured:"
echo "  Allow TCP:${AGENT_PORT} from ${AKS_PUBLIC_IP}/32"
