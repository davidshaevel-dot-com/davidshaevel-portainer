#!/usr/bin/env bash
# Orchestrated rebuild of the GKE environment.
# This script grows incrementally through the week:
#   v1 (Day 1): cluster + Portainer agent + Teleport agent
#   v2 (Day 2): + app deployment + Cloudflare DNS
#   v3 (Day 3): + Prometheus/Grafana stack

source "$(dirname "$0")/../config.sh"
setup_logging "gke-start"

SCRIPT_DIR="$(dirname "$0")"

echo "=========================================="
echo "  GKE Environment Rebuild (v1)"
echo "=========================================="
echo ""

# Step 1: Create cluster.
echo "--- Step 1/3: Create GKE cluster ---"
"${SCRIPT_DIR}/create.sh"

echo ""
echo "--- Step 2/3: Install Portainer Agent ---"
"${SCRIPT_DIR}/../portainer/gke-agent-install.sh"

echo ""
echo "--- Step 3/3: Install Teleport Agent ---"
"${SCRIPT_DIR}/../teleport/gke-agent-install.sh"

echo ""
echo "=========================================="
echo "  GKE Environment Ready"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Add GKE environment in Portainer UI (use the agent IP printed above)"
echo "  2. Verify 'portainer-gke' in Teleport: tctl kube ls"
