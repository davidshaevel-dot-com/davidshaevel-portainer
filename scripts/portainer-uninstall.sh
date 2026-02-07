#!/usr/bin/env bash
# Uninstall Portainer and clean up resources.

source "$(dirname "$0")/config.sh"
setup_logging "portainer-uninstall"

echo "WARNING: This will uninstall Portainer from the cluster."
echo "All Portainer data will be lost."
echo ""
read -p "Type 'portainer' to confirm uninstall: " confirm

if [ "${confirm}" != "portainer" ]; then
    echo "Confirmation failed. Aborting."
    exit 1
fi

echo "Uninstalling Portainer..."
helm uninstall portainer -n portainer

echo ""
echo "Deleting namespace 'portainer'..."
kubectl delete namespace portainer

echo ""
echo "Portainer uninstalled."
