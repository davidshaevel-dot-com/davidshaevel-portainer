# Work Session Agenda - February 6, 2026

## Goal

Set up the davidshaevel-portainer project and install Portainer BE on an AKS cluster in Azure.

**Context:** Following the [Build Your First Kubernetes Developer Platform](https://rawkode.academy/learning-paths/build-your-first-kubernetes-developer-platform) learning path from Rawkode Academy. The "Hands-on Introduction to Portainer" video has been watched. This session focuses on the hands-on installation.

---

## Completed (Pre-Agenda)

- [x] **Create project directory** with bare git worktree structure
- [x] **Initialize bare git repo** at `.bare/` with `main` worktree
- [x] **Create GitHub repo** (public): https://github.com/davidshaevel-dot-com/davidshaevel-portainer
- [x] **Add remote origin** to bare repo
- [x] **Create `.gitignore`** matching davidshaevel-platform conventions
- [x] **Create `CLAUDE.md`** with project context, architecture, conventions
- [x] **Create `CLAUDE.local.md`** with Azure subscription details (gitignored)
- [x] **Create `.claude/settings.json`** and `.claude/settings.local.json`
- [x] **Configure Linear MCP server** in `~/.claude.json` for this project
- [x] **Create Azure resource group** `portainer-rg` in `eastus`

---

## Agenda Items

### 1. Create Linear Project

- [ ] Create a new Linear project named "Portainer installation on Azure" under Team Tacocat
- [ ] Update CLAUDE.local.md with the project URL
- [ ] Create initial Linear issues for the work items below

### 2. Initial Git Commit & Push

- [ ] Stage all project files (CLAUDE.md, .gitignore, docs/)
- [ ] Create initial commit with project scaffolding
- [ ] Push main branch to GitHub

### 3. Create AKS Cluster

- [ ] Decide on cluster configuration:
  - **Cluster name:** e.g., `portainer-aks`
  - **Node count:** 1 (minimize cost for learning)
  - **VM size:** `Standard_B2s` or `Standard_DS2_v2` (cost-effective)
  - **Kubernetes version:** latest stable
- [ ] Create AKS cluster in `portainer-rg`
  ```bash
  az aks create \
    --resource-group portainer-rg \
    --name portainer-aks \
    --node-count 1 \
    --node-vm-size Standard_B2s \
    --generate-ssh-keys
  ```
- [ ] Get cluster credentials
  ```bash
  az aks get-credentials --resource-group portainer-rg --name portainer-aks
  ```
- [ ] Verify cluster access
  ```bash
  kubectl get nodes
  kubectl get sc  # Verify default StorageClass exists
  ```
- [ ] Update CLAUDE.local.md with cluster details

### 4. Install Portainer BE via Helm

Following [Portainer BE Install Docs](https://docs.portainer.io/start/install/server/kubernetes/baremetal):

- [ ] Add Portainer Helm repository
  ```bash
  helm repo add portainer https://portainer.github.io/k8s/
  helm repo update
  ```
- [ ] Install Portainer BE with LoadBalancer service type
  ```bash
  helm upgrade --install --create-namespace -n portainer portainer portainer/portainer \
    --set service.type=LoadBalancer \
    --set tls.force=true \
    --set enterpriseEdition.enabled=true \
    --set image.tag=lts
  ```
- [ ] Verify Portainer deployment
  ```bash
  kubectl get all -n portainer
  kubectl get svc -n portainer  # Get external IP
  ```
- [ ] Wait for LoadBalancer external IP assignment
- [ ] Access Portainer UI at `https://<EXTERNAL-IP>:9443`
- [ ] Complete initial Portainer setup (create admin user)
- [ ] Update CLAUDE.local.md with Portainer access URL

### 5. Explore Portainer

- [ ] Tour the Portainer dashboard
- [ ] Review the local Kubernetes environment in Portainer
- [ ] Explore cluster resources through the Portainer UI
- [ ] Deploy a sample application through Portainer (optional)

### 6. Document & Commit

- [ ] Update CLAUDE.md with any architecture changes
- [ ] Update CLAUDE.local.md session notes with what was accomplished
- [ ] Update learning path progress table in CLAUDE.md
- [ ] Commit and push all changes
- [ ] Update Linear issues with completion status

### 7. Cost Awareness

**Estimated Azure costs while cluster is running:**

| Component | Estimated Monthly Cost |
|-----------|----------------------|
| AKS Control Plane | Free |
| Standard_B2s node (1x) | ~$30/month |
| Azure Load Balancer | ~$18/month |
| Managed Disk (default PV) | ~$1-5/month |
| **Total** | **~$50-55/month** |

**Cost mitigation:**
- Stop the AKS cluster when not in use: `az aks stop --resource-group portainer-rg --name portainer-aks`
- Restart when needed: `az aks start --resource-group portainer-rg --name portainer-aks`
- Delete everything when done learning: `az group delete --name portainer-rg`

---

## Future Sessions (from Learning Path)

| Module | Description |
|--------|-------------|
| DevStand | Convert platform patterns into Jsonnet templates |
| Crossplane (Intro) | Extend Kubernetes APIs for cloud infrastructure |
| Crossplane (Action) | Package abstractions into platform building blocks |
| Waypoint | Standardize build/deploy/release workflows |
| Prometheus & Robusta | Monitoring and enriched alerting |

---

## References

- [Portainer BE Install Docs (K8s Baremetal)](https://docs.portainer.io/start/install/server/kubernetes/baremetal)
- [Rawkode Academy Learning Path](https://rawkode.academy/learning-paths/build-your-first-kubernetes-developer-platform)
- [Azure AKS Quickstart](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli)
- [AKS Start/Stop Cluster](https://learn.microsoft.com/en-us/azure/aks/start-stop-cluster)
