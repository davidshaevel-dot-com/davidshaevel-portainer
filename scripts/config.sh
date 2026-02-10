#!/usr/bin/env bash
# Shared configuration for all scripts.
# Source this file from subdirectory scripts: source "$(dirname "$0")/../config.sh"

set -euo pipefail

# --- Azure / AKS ---
RESOURCE_GROUP="portainer-rg"
AKS_CLUSTER_NAME="portainer-aks"
AKS_LOCATION="eastus"
AKS_NODE_COUNT=1
AKS_NODE_VM_SIZE="Standard_B2s"
SUBSCRIPTION="${AZURE_SUBSCRIPTION:?Set AZURE_SUBSCRIPTION in .envrc or environment}"

# --- GCP / GKE ---
GCP_PROJECT="${GCP_PROJECT:?Set GCP_PROJECT in .envrc or environment}"
GKE_CLUSTER_NAME="portainer-gke"
GKE_ZONE="us-central1-a"
GKE_MACHINE_TYPE="e2-medium"
GKE_NODE_COUNT=1

# Log directory for tailing script output from a separate terminal.
LOG_DIR="/tmp/${USER}-portainer"
mkdir -p "${LOG_DIR}"

# Call this at the top of each script after sourcing config.sh:
#   setup_logging "script-name"
# Then tail from another terminal:
#   tail -f /tmp/${USER}-portainer/script-name.log
setup_logging() {
    if [[ -z "${1:-}" ]]; then
        echo "Error: setup_logging requires a script name." >&2
        echo "Usage: setup_logging <script-name>" >&2
        exit 1
    fi
    local script_name="${1}"
    local log_file="${LOG_DIR}/${script_name}.log"
    echo "Logging to ${log_file}"
    echo "  tail -f ${log_file}"
    echo ""
    exec > >(tee "${log_file}") 2>&1
}
