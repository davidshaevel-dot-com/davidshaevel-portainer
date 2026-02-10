#!/usr/bin/env bash
# Stop (delete) the GKE cluster. GKE does not support stop/start like AKS,
# so this deletes the cluster. Use gke/start.sh to rebuild from scratch.

source "$(dirname "$0")/../config.sh"
setup_logging "gke-stop"

echo "GKE does not support stop/start. This will DELETE the cluster."
echo "Use ./scripts/gke/start.sh to rebuild it later."
echo ""

exec "$(dirname "$0")/delete.sh"
