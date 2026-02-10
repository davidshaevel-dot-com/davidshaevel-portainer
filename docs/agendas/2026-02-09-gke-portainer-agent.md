# Work Session Agenda - February 9, 2026

## Goal

Add a GKE cluster as a second environment managed through the existing AKS-hosted Portainer BE.

**Linear Issue:** [TT-147](https://linear.app/davidshaevel-dot-com/issue/TT-147/gke-cluster-portainer-agent-setup)
**Design Doc:** `docs/plans/2026-02-09-gke-portainer-agent-design.md`
**Context:** Day 1 Morning of Bumble Sr. SRE prep week.

---

## Pre-Session

- [x] Start AKS cluster (`scripts/aks-start.sh`)
- [x] Update DNS (`scripts/teleport-dns.sh`)
- [x] Verify Teleport access at https://teleport.davidshaevel.com
- [x] Re-authenticate GCP (`gcloud auth login`)
- [x] Write design document
- [x] Create Linear issue TT-147

---

## Agenda Items

### 1. Create Git Worktree

- [ ] Create worktree for TT-147
  ```bash
  cd /Users/dshaevel/workspace-ds/davidshaevel-portainer
  git worktree add tt-147-gke-portainer-agent -b claude/tt-147-gke-portainer-agent
  ```
- [ ] Copy gitignored files
  ```bash
  cp main/.envrc tt-147-gke-portainer-agent/.envrc
  cp main/CLAUDE.local.md tt-147-gke-portainer-agent/CLAUDE.local.md
  ```

### 2. Reorganize Scripts Directory

Move existing flat scripts into component subdirectories:

- [ ] Create subdirectories: `scripts/aks/`, `scripts/gke/`, `scripts/portainer/`, `scripts/teleport/`
- [ ] Move AKS scripts → `scripts/aks/` (drop `aks-` prefix)
- [ ] Move Portainer scripts → `scripts/portainer/` (rename to `aks-install.sh`, `aks-uninstall.sh`, `aks-status.sh`)
- [ ] Move Teleport scripts → `scripts/teleport/` (rename agent scripts to `aks-agent-install.sh`, `aks-agent-uninstall.sh`)
- [ ] Update `source` paths in all moved scripts
- [ ] Update references in CLAUDE.md, README.md, CLAUDE.local.md
- [ ] Verify existing AKS scripts still work after reorganization

### 3. Add GCP Config

- [ ] Add GKE variables to `scripts/config.sh`
- [ ] Add `GCP_PROJECT` to `.envrc.example`
- [ ] Add `GCP_PROJECT` to `.envrc`

### 4. Write GKE Scripts

- [ ] `scripts/gke/create.sh` — Enable GKE API, create cluster, get credentials
- [ ] `scripts/gke/delete.sh` — Delete GKE cluster
- [ ] `scripts/gke/start.sh` — Orchestrated rebuild (v1: cluster + agent + firewall + Teleport)
- [ ] `scripts/gke/stop.sh` — Alias for delete
- [ ] `scripts/gke/status.sh` — Show cluster status
- [ ] `scripts/gke/credentials.sh` — Fetch kubeconfig
- [ ] `scripts/gke/firewall.sh` — GCP firewall rule (AKS egress IP → port 9001)

### 5. Write Portainer Agent Scripts

- [ ] `scripts/portainer/gke-agent-install.sh` — Install Standard Agent via Helm on GKE
- [ ] `scripts/portainer/gke-agent-uninstall.sh` — Remove agent

### 6. Write Teleport GKE Agent Scripts

- [ ] `scripts/teleport/gke-agent-install.sh` — Deploy Teleport kube agent, register as `portainer-gke`
- [ ] `scripts/teleport/gke-agent-uninstall.sh` — Remove Teleport agent from GKE

### 7. Execute Setup

- [ ] Enable GKE API on `dev-david-024680`
- [ ] Create GKE cluster (`e2-medium`, 1 node, `us-central1-a`)
- [ ] Get AKS egress IP and create GCP firewall rule
- [ ] Install Portainer Agent on GKE
- [ ] Add GKE environment in Portainer UI (agent IP:9001)
- [ ] Deploy Teleport kube agent on GKE

### 8. Verify

- [ ] GKE cluster visible as second environment in Portainer dashboard
- [ ] Can browse GKE nodes, pods, services from Portainer UI
- [ ] `portainer-gke` appears in Teleport (`tctl kube ls`)
- [ ] `tsh kube login portainer-gke && kubectl get nodes` works

### 9. Update Documentation

- [ ] CLAUDE.md — architecture diagram, repo structure, helpful commands, references
- [ ] README.md — architecture diagram, scripts table, setup steps
- [ ] CLAUDE.local.md — GKE cluster details, session notes

### 10. PR + Code Review

- [ ] Commit all changes
- [ ] Push branch and create PR
- [ ] Wait for code review
- [ ] Address feedback and merge

---

## Cost

| Component | Daily |
|-----------|-------|
| GKE `e2-medium` (1 node) | ~$1.50 |
| GCP Load Balancer (agent) | ~$0.60 |
| AKS (already running) | ~$1.60 |
| **Total** | **~$4-5/day** |

Delete GKE when done: `scripts/gke/delete.sh`
