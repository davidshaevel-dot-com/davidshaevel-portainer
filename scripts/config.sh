#!/usr/bin/env bash
# Shared configuration for all AKS scripts.
# Source this file from other scripts: source "$(dirname "$0")/config.sh"

set -euo pipefail

RESOURCE_GROUP="portainer-rg"
CLUSTER_NAME="portainer-aks"
LOCATION="eastus"
NODE_COUNT=1
NODE_VM_SIZE="Standard_B2s"
SUBSCRIPTION="${AZURE_SUBSCRIPTION:?Set AZURE_SUBSCRIPTION in .envrc or environment}"

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
