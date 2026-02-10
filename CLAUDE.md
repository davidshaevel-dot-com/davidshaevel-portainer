# Portainer on Azure Kubernetes - Claude Context

<!-- If CLAUDE.local.md exists, read it for additional context (Azure resource IDs, cluster details, etc.) -->

## Project Overview

This is a hands-on learning project for getting practical experience with Kubernetes and Portainer. The project follows the [Build Your First Kubernetes Developer Platform](https://rawkode.academy/learning-paths/build-your-first-kubernetes-developer-platform) learning path from Rawkode Academy, starting with Portainer installation on an Azure Kubernetes Service (AKS) cluster.

**Key Technologies:**
- **Cloud:** Azure (AKS), Google Cloud (GKE)
- **Container Orchestration:** Kubernetes (multi-cluster)
- **Platform Management:** Portainer Business Edition (BE)
- **Secure Access:** Teleport Community Edition (self-hosted)
- **IaC:** Azure CLI, gcloud CLI, Helm
- **DNS:** Cloudflare (API-managed)
- **CLI Tools:** kubectl, helm, az, gcloud, tsh, tctl

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
Azure Load Balancer (Teleport)
    │
    ▼
AKS Cluster (portainer-rg, eastus)
    │
    ├── teleport-cluster namespace
    │       │
    │       ├── Teleport Auth (ClusterIP)
    │       ├── Teleport Proxy (port 443 HTTPS, LoadBalancer)
    │       │       +-- Web UI:   https://teleport.davidshaevel.com
    │       │       +-- App Proxy: routes to Portainer (ClusterIP)
    │       │       +-- K8s Proxy: authenticated kubectl access
    │       └── Teleport Agent (app + kube registration)
    │
    ├── portainer namespace
    │       │
    │       ▼
    │   Portainer BE (ClusterIP, port 9443 HTTPS)
    │       │  (no public IP, accessed via Teleport)
    │       │  Manages: AKS (local) + GKE (remote agent)
    │       ▼
    │   Persistent Volume (default StorageClass)
    │
    └── (future namespaces for learning path modules)

GKE Cluster (dev-david-024680, us-central1-a)
    │
    ├── portainer namespace
    │       └── Portainer Agent (LoadBalancer, port 9001)
    │               (firewall: port 9001 restricted to AKS egress IP)
    │
    └── teleport-cluster namespace
            └── Teleport Kube Agent (registered as "portainer-gke")
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
2. **Wait for review** (Gemini Code Assist or human reviewer)
3. **Address feedback:**
   - CRITICAL and HIGH issues: Must fix
   - MEDIUM issues: Evaluate and decide
4. **Post summary comment** with all fixes addressed
5. **Merge only after** all review feedback resolved

**Merge Strategy:** Always use **Squash and Merge** for pull requests.

```bash
# Merge PR with squash
gh pr merge <PR_NUMBER> --squash

# Delete the remote branch (--delete-branch doesn't work with worktrees)
git push origin --delete <branch-name>
```

#### Reply to Review Comments

Reply **in the comment thread** (not top-level):

**IMPORTANT: Always start with `@gemini-code-assist` so they are notified of your response.**

```bash
gh api repos/davidshaevel-dot-com/davidshaevel-portainer/pulls/<PR>/comments/<COMMENT_ID>/replies \
  -f body="@gemini-code-assist Fixed. Changed X to Y."
```

Every inline reply must include:
- **`@gemini-code-assist` at the start** (required for notification)
- What was fixed and how
- Technical reasoning if declining

#### Post Summary Comment

Add a summary comment to the PR:

**IMPORTANT: Always start with `@gemini-code-assist` so they are notified.**

```markdown
@gemini-code-assist Review addressed:

| # | Feedback | Resolution |
|---|----------|------------|
| 1 | Issue X | Fixed in abc123 - Added validation for edge case |
| 2 | Issue Y | Fixed in abc123 - Refactored to use recommended pattern |
| 3 | Issue Z | Declined - YAGNI, feature not currently used |
```

**Resolution column format:** Include both the commit reference AND a brief summary of how the feedback was addressed.

---

## Portainer Installation Reference

**Source:** [Portainer BE Kubernetes Install (Baremetal)](https://docs.portainer.io/start/install/server/kubernetes/baremetal)

### Prerequisites
- Running Kubernetes cluster with RBAC enabled
- `helm` or `kubectl` with cluster admin privileges
- Default StorageClass configured
- Kubernetes metrics server installed

### Helm Installation (ClusterIP via Teleport)
```bash
helm repo add portainer https://portainer.github.io/k8s/
helm repo update

helm upgrade --install --create-namespace --wait -n portainer portainer portainer/portainer \
    --set service.type=ClusterIP \
    --set tls.force=true \
    --set enterpriseEdition.enabled=true \
    --set image.tag=lts \
    --set trusted_origins.enabled=true \
    --set trusted_origins.domains="portainer.teleport.davidshaevel.com"
```

> **Known Issue:** The Portainer Helm chart wraps `--trusted-origins` values in escaped double quotes, causing CSRF validation to fail. The `scripts/portainer/aks-install.sh` script patches the deployment args after install as a workaround.

### Access
- **Via Teleport:** `https://teleport.davidshaevel.com` (Portainer app in sidebar)

---

## Helpful Commands

```bash
# Azure CLI
az login
az account set --subscription "DavidShaevel.com Subscription Two"
az group list --output table

# AKS
az aks get-credentials --resource-group portainer-rg --name portainer-aks
az aks list --resource-group portainer-rg --output table

# GKE
gcloud container clusters get-credentials portainer-gke --zone us-central1-a --project <project-id>
gcloud container clusters list --project <project-id>

# Kubernetes
kubectl get nodes
kubectl get sc                    # Check StorageClass
kubectl get all -n portainer      # Check Portainer resources
kubectl get all -n teleport-cluster  # Check Teleport resources

# Helm
helm list -A                       # All Helm releases
helm status portainer -n portainer
helm status teleport-cluster -n teleport-cluster
helm status teleport-agent -n teleport-cluster

# Teleport client (tsh) - requires tsh installed locally
tsh login --proxy=teleport.davidshaevel.com --user=admin
tsh kube ls                       # List available kube clusters
tsh kube login portainer-aks      # Switch kubectl to AKS via Teleport
tsh kube login portainer-gke      # Switch kubectl to GKE via Teleport
tsh logout                        # Log out (re-login to refresh roles)

# Teleport admin (via auth pod) - no tsh required
kubectl exec -n teleport-cluster deployment/teleport-cluster-auth -- tctl status
kubectl exec -n teleport-cluster deployment/teleport-cluster-auth -- tctl users ls
kubectl exec -n teleport-cluster deployment/teleport-cluster-auth -- tctl apps ls
kubectl exec -n teleport-cluster deployment/teleport-cluster-auth -- tctl kube ls

# Git worktrees
git worktree list
git worktree add <issue-id>-<description> -b claude/<issue-id>-<description>
git worktree remove <worktree-name>
```

---

## Script Execution & Logging

All scripts and `az` CLI commands should tee output to `/tmp/${USER}-portainer/` so David can `tail -f` from a separate terminal.

**For scripts:** Each script calls `setup_logging "script-name"` (from `scripts/config.sh`) which tees all output to `/tmp/${USER}-portainer/<script-name>.log`.

**For ad-hoc az/kubectl commands run by Claude Code:** Pipe through tee:
```bash
az aks show ... 2>&1 | tee /tmp/${USER}-portainer/ad-hoc.log
```

**Tailing from a separate terminal:**
```bash
tail -f /tmp/${USER}-portainer/aks-create.log
```

---

## Environment Variables

Environment-specific values are stored in `.envrc` (gitignored). A committed `.envrc.example` documents the required variables.

**Setup:**
```bash
cp .envrc.example .envrc
# Edit .envrc with your values
```

**With direnv:** `.envrc` is auto-sourced when you `cd` into the project.

**Without direnv:** Source manually before running scripts:
```bash
source .envrc
```

**Current variables:**

| Variable | Used By | Purpose |
|----------|---------|---------|
| `AZURE_SUBSCRIPTION` | `scripts/config.sh` | Azure subscription name or ID for all `az` commands |
| `GCP_PROJECT` | `scripts/config.sh` | GCP project ID for GKE cluster |
| `CLOUDFLARE_API_TOKEN` | `scripts/teleport/dns.sh` | Cloudflare API token with DNS edit permissions |
| `CLOUDFLARE_ZONE_ID` | `scripts/teleport/dns.sh` | Cloudflare zone ID for davidshaevel.com |
| `TELEPORT_ACME_EMAIL` | `scripts/teleport/install.sh` | Email for Let's Encrypt ACME certificate notifications |

Scripts will error with a clear message if a required env var is missing.

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
│   ├── .envrc                         # Environment variables (gitignored)
│   ├── .envrc.example                 # Template for .envrc (committed)
│   ├── .gitignore                     # Git ignore patterns
│   ├── scripts/                       # Reusable az/kubectl/helm/gcloud scripts
│   │   ├── config.sh                  # Shared configuration (sourced by all scripts)
│   │   ├── aks/                       # AKS cluster lifecycle
│   │   ├── gke/                       # GKE cluster lifecycle + firewall
│   │   ├── portainer/                 # Portainer server + agent install/uninstall
│   │   └── teleport/                  # Teleport server + agent install/uninstall
│   └── docs/                          # Documentation
│       ├── agendas/                   # Work session agendas
│       └── plans/                     # Design documents and plans
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
- **Portainer Agent Install:** [Add Kubernetes via Agent](https://docs.portainer.io/admin/environments/add/kubernetes/agent)
- **Azure AKS Docs:** [Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/)
- **Google GKE Docs:** [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs)
- **Teleport Helm Deploy:** [Deploy on Kubernetes](https://goteleport.com/docs/deploy-a-cluster/helm-deployments/kubernetes-cluster/)
- **Teleport App Access:** [Application Access](https://goteleport.com/docs/application-access/)
- **Teleport K8s Access:** [Kubernetes Access](https://goteleport.com/docs/kubernetes-access/)
- **Cloudflare DNS API:** [DNS Records](https://developers.cloudflare.com/api/resources/dns/subresources/records/)
