# Multi-Cloud Kubernetes Platform

A multi-cloud Kubernetes management platform with zero-trust access, cost-optimized lifecycle automation, and programmatic environment registration. Manages AKS and GKE clusters through Portainer Business Edition with Teleport-secured access — no direct public endpoints exposed.

## Architecture

```
Internet
    |
    v
Azure Load Balancer (port 443)
    |
    v
AKS Cluster (portainer-rg, eastus)
    |
    +-- teleport-cluster namespace
    |       |
    |       +-- Teleport Proxy (HTTPS, LoadBalancer)
    |       |       Web UI:   https://teleport.<your-domain>.com
    |       |       App Proxy: routes to Portainer (ClusterIP)
    |       |       K8s Proxy: authenticated kubectl access
    |       |
    |       +-- Teleport Auth (ClusterIP)
    |       +-- Teleport Agent (app + kube registration)
    |
    +-- portainer namespace
            |
            Portainer BE (ClusterIP, port 9443 HTTPS)
                (no public IP, accessed via Teleport)
                Manages: AKS (local) + GKE (remote agent)

GKE Cluster (us-central1-a)
    |
    +-- portainer namespace
    |       +-- Portainer Agent (LoadBalancer, port 9001)
    |               (loadBalancerSourceRanges: AKS egress IP only)
    |
    +-- teleport-cluster namespace
            +-- Teleport Kube Agent (kubectl access via Teleport)
```

All traffic flows through Teleport. Portainer has no public endpoint. The GKE Portainer Agent LoadBalancer is restricted to the AKS cluster's egress IP via `loadBalancerSourceRanges`.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Cloud | Azure (AKS), Google Cloud (GKE) |
| Container Orchestration | Kubernetes (multi-cluster) |
| Platform Management | Portainer Business Edition |
| Secure Access | Teleport Community Edition (self-hosted) |
| CI/CD | GitHub Actions (workflow_dispatch) |
| DNS | Cloudflare (API-managed) |
| TLS | Let's Encrypt (ACME via Teleport) |
| IaC | Azure CLI, gcloud CLI, Helm |

## GitHub Actions Workflows

All workflows are triggered manually via `workflow_dispatch` from the GitHub Actions UI.

| Workflow | Description |
|----------|-------------|
| **AKS Start** | Start the AKS cluster, wait for pods, update Cloudflare DNS, verify Teleport accessibility |
| **AKS Stop** | Optionally delete DNS records, stop the AKS cluster to save costs |
| **GKE Start** | Create GKE cluster, install Portainer Agent, register in Portainer via API, install Teleport Agent. Auto-deletes cluster on failure to prevent costs |
| **GKE Stop** | Optionally deregister from Portainer via API, delete the GKE cluster |

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | Azure service principal JSON (`az ad sp create-for-rbac --json-auth`) |
| `AZURE_SUBSCRIPTION` | Azure subscription name or ID |
| `GCP_CREDENTIALS_JSON` | GCP service account key JSON |
| `GCP_PROJECT` | GCP project ID |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token (Zone:DNS:Edit) |
| `CLOUDFLARE_ZONE_ID` | Cloudflare zone ID |
| `TELEPORT_ACME_EMAIL` | Email for Let's Encrypt certificates |
| `PORTAINER_ADMIN_PASSWORD` | Portainer admin password for API automation |

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az`)
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) (`gcloud`) with `gke-gcloud-auth-plugin`
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- [jq](https://jqlang.github.io/jq/download/)
- An Azure subscription
- A GCP project with billing enabled
- A Cloudflare-managed domain (for DNS)
- A Portainer Business Edition license key

## Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/davidshaevel-dot-com/davidshaevel-portainer.git
   cd davidshaevel-portainer
   ```

2. **Configure environment variables:**

   ```bash
   cp .envrc.example .envrc
   # Edit .envrc with your values
   ```

   If using [direnv](https://direnv.net/), `.envrc` is auto-sourced. Otherwise, source manually:

   ```bash
   source .envrc
   ```

3. **Create the AKS cluster:**

   ```bash
   ./scripts/aks/create.sh
   ```

4. **Install Portainer:**

   ```bash
   ./scripts/portainer/aks-install.sh
   ```

5. **Install Teleport and configure DNS:**

   ```bash
   ./scripts/teleport/install.sh
   ./scripts/teleport/dns.sh
   ```

   Wait a few minutes for DNS propagation and TLS certificate issuance, then verify `https://<your-teleport-domain>` is accessible before continuing.

6. **Deploy the Teleport agent** (registers Portainer app and Kubernetes cluster):

   ```bash
   ./scripts/teleport/aks-agent-install.sh
   ```

7. **Add a GKE cluster** (optional, multi-cluster setup):

   ```bash
   ./scripts/gke/start.sh
   ```

   This creates the cluster, installs and registers the Portainer Agent via API, and installs the Teleport kube agent.

## Scripts

All scripts source `scripts/config.sh` for shared configuration. When running locally, output is logged to `/tmp/$USER-portainer/`. In CI (GitHub Actions), file logging is skipped — the runner captures output natively.

### AKS Cluster (`scripts/aks/`)

| Script | Description |
|--------|-------------|
| `aks/create.sh` | Create the AKS cluster |
| `aks/delete.sh` | Delete the AKS cluster |
| `aks/start.sh` | Start a stopped cluster |
| `aks/stop.sh` | Stop the cluster (save costs) |
| `aks/status.sh` | Show cluster status |
| `aks/credentials.sh` | Fetch kubeconfig credentials |

### GKE Cluster (`scripts/gke/`)

| Script | Description |
|--------|-------------|
| `gke/create.sh` | Create the GKE cluster (enables API if needed) |
| `gke/delete.sh` | Delete the GKE cluster (interactive, requires confirmation) |
| `gke/start.sh` | Orchestrated rebuild (create + agents + registration) |
| `gke/stop.sh` | Delete the GKE cluster (non-interactive, for scripted use) |
| `gke/status.sh` | Show cluster status |
| `gke/credentials.sh` | Fetch kubeconfig credentials |

### Portainer (`scripts/portainer/`)

| Script | Description |
|--------|-------------|
| `portainer/aks-install.sh` | Install Portainer BE server via Helm on AKS |
| `portainer/aks-uninstall.sh` | Uninstall Portainer server |
| `portainer/aks-status.sh` | Show Portainer deployment status |
| `portainer/gke-agent-install.sh` | Install Portainer Agent on GKE via kubectl manifest |
| `portainer/gke-agent-uninstall.sh` | Remove Portainer Agent from GKE |
| `portainer/gke-agent-register.sh` | Register GKE endpoint in Portainer via REST API |
| `portainer/gke-agent-deregister.sh` | Remove GKE endpoint from Portainer via REST API |
| `portainer/gke-agent-restrict-lb.sh` | Restrict Agent LoadBalancer to AKS egress IP only |

### Teleport (`scripts/teleport/`)

| Script | Description |
|--------|-------------|
| `teleport/install.sh` | Install Teleport Community Edition via Helm |
| `teleport/uninstall.sh` | Uninstall Teleport |
| `teleport/status.sh` | Show Teleport deployment status |
| `teleport/dns.sh` | Create/update Cloudflare DNS records (A + wildcard) |
| `teleport/dns-delete.sh` | Delete Cloudflare DNS records |
| `teleport/aks-agent-install.sh` | Deploy Teleport agent on AKS (app + kube registration) |
| `teleport/aks-agent-uninstall.sh` | Remove Teleport agent from AKS |
| `teleport/gke-agent-install.sh` | Deploy Teleport kube agent on GKE |
| `teleport/gke-agent-uninstall.sh` | Remove Teleport agent from GKE |

### GitHub Actions Setup (`scripts/github/`)

| Script | Description |
|--------|-------------|
| `github/create-azure-sp.sh` | Create Azure service principal for GitHub Actions |
| `github/create-gcp-sa.sh` | Create GCP service account for GitHub Actions |
| `github/configure-secrets.sh` | Configure all required GitHub repository secrets |

## Environment Variables

Defined in `.envrc` (gitignored). See [.envrc.example](.envrc.example) for the template.

| Variable | Purpose |
|----------|---------|
| `AZURE_SUBSCRIPTION` | Azure subscription name or ID |
| `GCP_PROJECT` | GCP project ID for GKE cluster |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token (Zone:DNS:Edit) |
| `CLOUDFLARE_ZONE_ID` | Cloudflare zone ID for the domain |
| `TELEPORT_ACME_EMAIL` | Email for Let's Encrypt certificate notifications |
| `PORTAINER_ADMIN_PASSWORD` | Portainer admin password for API automation |

## Project Management

- **Issue Tracking:** [Linear (Team Tacocat)](https://linear.app/davidshaevel-dot-com/project/portainer-installation-on-azure-ffad47e35e49)
- **Repository:** [GitHub](https://github.com/davidshaevel-dot-com/davidshaevel-portainer)

## Cost Estimate

| Component | Monthly Cost |
|-----------|-------------|
| AKS control plane | Free |
| AKS Standard_B2s node (1x) | ~$30 |
| AKS Load Balancer (Teleport) | ~$18 |
| AKS Managed Disks (PVs) | ~$1-5 |
| GKE Autopilot/Standard (e2-medium) | ~$25 |
| **Total** | **~$75-80** |

Stop AKS when not in use: `./scripts/aks/stop.sh` or run the **AKS Stop** workflow. Delete GKE when not in use: `./scripts/gke/stop.sh` or run the **GKE Stop** workflow (GKE has no stop/start — use `./scripts/gke/start.sh` or the **GKE Start** workflow to rebuild).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
