#!/usr/bin/env bash
# Delete the AKS cluster. Prompts for confirmation.

source "$(dirname "$0")/config.sh"
setup_logging "aks-delete"

echo "WARNING: This will delete the AKS cluster '${CLUSTER_NAME}' in '${RESOURCE_GROUP}'."
echo "All workloads and data on the cluster will be lost."
echo ""
read -p "Type the cluster name to confirm deletion: " confirm

if [ "${confirm}" != "${CLUSTER_NAME}" ]; then
    echo "Confirmation failed. Aborting."
    exit 1
fi

echo "Deleting AKS cluster '${CLUSTER_NAME}'..."

az aks delete \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${CLUSTER_NAME}" \
    --yes

echo "Cluster '${CLUSTER_NAME}' deleted."
