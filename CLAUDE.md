# Portainer on Azure Kubernetes - Claude Context

<!-- If CLAUDE.local.md exists, read it for additional context (Azure resource IDs, cluster details, etc.) -->

## Project Overview

This is a hands-on learning project for getting practical experience with Kubernetes and Portainer. The project follows the [Build Your First Kubernetes Developer Platform](https://rawkode.academy/learning-paths/build-your-first-kubernetes-developer-platform) learning path from Rawkode Academy, starting with Portainer installation on an Azure Kubernetes Service (AKS) cluster.

**Key Technologies:**
- **Cloud:** Azure (AKS, Resource Groups)
- **Container Orchestration:** Kubernetes
- **Platform Management:** Portainer Business Edition (BE)
- **IaC:** Azure CLI, Helm
- **CLI Tools:** kubectl, helm, az

**Project Management:**
- **Issue Tracking:** Linear (Team Tacocat)
- **Version Control:** GitHub
- **Branching Strategy:** Feature branches with PR workflow

---

## Development Approach

Use the **superpowers skills** whenever they are relevant. This includes but is not limited to:
- `superpowers:brainstorming` - Before any creative work or feature implementation
- `superpowers:writing-plans` - When planning multi-step tasks
- `superpowers:systematic-debugging` - When encountering bugs or unexpected behavior
- `superpowers:verification-before-completion` - Before claiming work is complete
- `superpowers:requesting-code-review` - When completing major features
- `superpowers:using-git-worktrees` - When starting feature work that needs isolation

If there's even a 1% chance a skill applies, invoke it.

---

## Architecture

```
Internet
    │
    ▼
Azure Load Balancer
    │
    ▼
AKS Cluster (portainer-rg)
    │
    ├── portainer namespace
    │       │
    │       ▼
    │   Portainer BE (port 9443 HTTPS)
    │       │
    │       ▼
    │   Persistent Volume (default StorageClass)
    │
    └── (future namespaces for learning path modules)
```

---

## Learning Path Progress

This project follows the Rawkode Academy learning path (~4.5 hours total):

| # | Module | Status |
|---|--------|--------|
| 1 | Hands-on Introduction to Portainer | Video watched |
| 2 | Hands-on Introduction to DevStand | Not started |
| 3 | Introduction to Crossplane | Not started |
| 4 | Crossplane in Action | Not started |
| 5 | Hands-on Introduction to Waypoint | Not started |
| 6 | Monitoring with Prometheus & Robusta | Not started |

---

## Development Process & Conventions

### Git Workflow

**Branch Naming Convention:**
```
claude/<issue-id>-<brief-description>
david/<issue-id>-<brief-description>
```

**Commit Message Format (Conventional Commits):**

```
<type>(<scope>): <short description>

Longer description if needed.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

related-issues: TT-XXX
```

**Types:** `feat`, `fix`, `docs`, `chore`, `refactor`, `test`

**Scope Guidelines:**
- The scope should be a **descriptive word or hyphenated phrase** that identifies the feature or area being changed
- **DO NOT** use issue numbers as the scope - issue numbers go in `related-issues:`
- Good scopes: `portainer`, `aks`, `helm`, `cluster`
- Bad scopes: `TT-140`, `azure`

### Pull Request Process

**CRITICAL: NEVER MERGE WITHOUT CODE REVIEW**

1. **Create PR** with descriptive title and comprehensive description
2. **Wait for review**
3. **Address feedback** before merging
4. **Merge Strategy:** Always use **Squash and Merge**

```bash
# Merge PR with squash
gh pr merge <PR_NUMBER> --squash

# Delete the remote branch
git push origin --delete <branch-name>
```

---

## Portainer Installation Reference

**Source:** [Portainer BE Kubernetes Install (Baremetal)](https://docs.portainer.io/start/install/server/kubernetes/baremetal)

### Prerequisites
- Running Kubernetes cluster with RBAC enabled
- `helm` or `kubectl` with cluster admin privileges
- Default StorageClass configured
- Kubernetes metrics server installed

### Helm Installation (Load Balancer)
```bash
helm repo add portainer https://portainer.github.io/k8s/
helm repo update

helm upgrade --install --create-namespace -n portainer portainer portainer/portainer \
    --set service.type=LoadBalancer \
    --set tls.force=true \
    --set enterpriseEdition.enabled=true \
    --set image.tag=lts
```

### Access
- **Load Balancer:** `https://<loadbalancer-IP>:9443/`

---

## Helpful Commands

```bash
# Azure CLI
az login
az account set --subscription "DavidShaevel.com Subscription Two"
az group list --output table

# AKS
az aks get-credentials --resource-group portainer-rg --name <cluster-name>
az aks list --resource-group portainer-rg --output table

# Kubernetes
kubectl get nodes
kubectl get sc                    # Check StorageClass
kubectl get all -n portainer      # Check Portainer resources
kubectl get svc -n portainer      # Get Portainer service IP

# Helm
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
helm list -n portainer
helm status portainer -n portainer

# Git worktrees
git worktree list
git worktree add <issue-id>-<description> -b claude/<issue-id>-<description>
git worktree remove <worktree-name>
```

---

## Key Conventions Summary

- **Always use feature branches** named `claude/<issue>-<description>` or `david/<issue>-<description>`
- **Conventional Commits** with `related-issues: TT-XXX`
- **Squash and merge** for all PRs
- **Never commit sensitive data** (kubeconfig, .envrc, credentials)
- **Use superpowers skills** when they apply
- **Document decisions** in session notes

---

## Repository Structure

```
davidshaevel-portainer/
│
├── .bare/                             # Bare git repository
├── .git                               # Points to .bare
├── .wakatime-project                  # WakaTime project name
│
├── main/                              # Main branch worktree
│   ├── CLAUDE.md                      # Public project context (this file)
│   ├── CLAUDE.local.md                # Sensitive project context (gitignored)
│   ├── .gitignore                     # Git ignore patterns
│   └── docs/                          # Documentation
│       └── agendas/                   # Work session agendas
│
└── <feature-worktrees>/               # Feature branch worktrees (flat!)
```

### Working with Worktrees

This repo uses a bare repository with git worktrees, allowing multiple branches to be checked out simultaneously.

**IMPORTANT: Flattened Folder Structure**

Worktrees are created directly in `davidshaevel-portainer/`, NOT in nested subdirectories.

```bash
# Correct structure:
davidshaevel-portainer/
├── .bare
├── main
├── tt-140-aks-cluster              # Feature worktree (flat!)
└── tt-141-portainer-install        # Another feature (flat!)

# WRONG - do not create nested structures like:
davidshaevel-portainer/claude/tt-140-aks-cluster  # NO!
```

**Commands:**

```bash
# Create a new feature branch worktree (FLAT structure!)
cd /Users/dshaevel/workspace-ds/davidshaevel-portainer
git worktree add <issue-id>-<brief-description> -b claude/<issue-id>-<brief-description>

# Remove a worktree when done
git worktree remove <worktree-folder-name>
```

### Worktree Cleanup - IMPORTANT

**Before removing a worktree**, copy any gitignored files to the main worktree:

```bash
cp <worktree-name>/.envrc main/.envrc
cp <worktree-name>/CLAUDE.local.md main/CLAUDE.local.md
```

**Workflow:**
1. Merge PR: `gh pr merge <PR_NUMBER> --squash`
2. Pull changes into main worktree: `cd main && git pull`
3. Delete remote branch: `git push origin --delete <branch-name>`
4. Copy gitignored files from feature worktree to main
5. Remove the worktree: `git worktree remove <worktree-name>`

---

## References

- **Learning Path:** [Build Your First Kubernetes Developer Platform](https://rawkode.academy/learning-paths/build-your-first-kubernetes-developer-platform)
- **Portainer BE Install Docs:** [Kubernetes Baremetal](https://docs.portainer.io/start/install/server/kubernetes/baremetal)
- **Azure AKS Docs:** [Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/)
