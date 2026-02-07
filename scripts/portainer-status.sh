#!/usr/bin/env bash
# Show Portainer deployment status and access URL.

source "$(dirname "$0")/config.sh"
setup_logging "portainer-status"

echo "=== Helm Release ==="
helm status portainer -n portainer 2>/dev/null || echo "Portainer not installed via Helm."

echo ""
echo "=== Pods ==="
kubectl get pods -n portainer

echo ""
echo "=== Services ==="
kubectl get svc -n portainer

echo ""
echo "=== Access URL ==="
EXTERNAL_IP=$(kubectl get svc portainer -n portainer -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -n "${EXTERNAL_IP}" ]; then
    echo "  https://${EXTERNAL_IP}:9443/"
else
    echo "  LoadBalancer IP not yet assigned. Run: kubectl get svc -n portainer -w"
fi
