#!/usr/bin/env bash
# Start a stopped AKS cluster.

source "$(dirname "$0")/config.sh"
setup_logging "aks-start"

echo "Starting AKS cluster '${CLUSTER_NAME}'..."

az aks start \
    --subscription "${SUBSCRIPTION}" \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${CLUSTER_NAME}"

echo "Cluster '${CLUSTER_NAME}' started."
