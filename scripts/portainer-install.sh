#!/usr/bin/env bash
# Install Portainer Business Edition via Helm.
# Reference: https://docs.portainer.io/start/install/server/kubernetes/baremetal

source "$(dirname "$0")/config.sh"
setup_logging "portainer-install"

echo "Adding Portainer Helm repository..."
helm repo add portainer https://portainer.github.io/k8s/
helm repo update

echo ""
echo "Installing Portainer BE in namespace 'portainer'..."
echo "  Service type: LoadBalancer"
echo "  TLS forced:   true"
echo "  Edition:      Business (Enterprise)"
echo "  Image tag:    lts"
echo ""

helm upgrade --install --create-namespace --wait -n portainer portainer portainer/portainer \
    --set service.type=LoadBalancer \
    --set tls.force=true \
    --set enterpriseEdition.enabled=true \
    --set image.tag=lts

echo ""
echo "Portainer installed. Checking deployment status..."
echo ""

echo "=== Pods ==="
kubectl get pods -n portainer

echo ""
echo "=== Services ==="
kubectl get svc -n portainer

echo ""
echo "Waiting for LoadBalancer external IP (this may take a few minutes)..."
EXTERNAL_IP=""
ATTEMPTS=0
MAX_ATTEMPTS=36  # 3 minutes (36 * 5 seconds)
while [ -z "${EXTERNAL_IP}" ] && [ "${ATTEMPTS}" -lt "${MAX_ATTEMPTS}" ]; do
    EXTERNAL_IP=$(kubectl get svc portainer -n portainer -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    if [ -z "${EXTERNAL_IP}" ]; then
        echo -n "."
        sleep 5
        ATTEMPTS=$((ATTEMPTS + 1))
    fi
done
echo ""
if [ -n "${EXTERNAL_IP}" ]; then
    echo "Portainer is available at: https://${EXTERNAL_IP}:9443/"
else
    echo "LoadBalancer IP not assigned after 3 minutes."
    echo "Run: kubectl get svc -n portainer -w"
fi
