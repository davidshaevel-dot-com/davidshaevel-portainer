#!/usr/bin/env bash
# Create an AKS cluster in the portainer-rg resource group.
# This is a one-time setup script.

source "$(dirname "$0")/config.sh"
setup_logging "aks-create"

echo "Creating AKS cluster '${CLUSTER_NAME}' in resource group '${RESOURCE_GROUP}'..."
echo "  Location:    ${LOCATION}"
echo "  Node count:  ${NODE_COUNT}"
echo "  VM size:     ${NODE_VM_SIZE}"
echo ""

az aks create \
    --subscription "${SUBSCRIPTION}" \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${CLUSTER_NAME}" \
    --node-count "${NODE_COUNT}" \
    --node-vm-size "${NODE_VM_SIZE}" \
    --location "${LOCATION}" \
    --generate-ssh-keys \
    --output table

echo ""
echo "AKS cluster '${CLUSTER_NAME}' created successfully."
echo "Run ./scripts/aks-credentials.sh to configure kubectl access."
