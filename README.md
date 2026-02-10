# Portainer on Multi-Cloud Kubernetes

A hands-on learning project for getting practical experience with Kubernetes and Portainer, following the [Build Your First Kubernetes Developer Platform](https://rawkode.academy/learning-paths/build-your-first-kubernetes-developer-platform) learning path from Rawkode Academy.

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
| DNS | Cloudflare (API-managed) |
| TLS | Let's Encrypt (ACME via Teleport) |
| IaC | Azure CLI, gcloud CLI, Helm |

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
   ./scripts/gke/create.sh
   ./scripts/portainer/gke-agent-install.sh
   ./scripts/teleport/gke-agent-install.sh
   ```

   Then add the GKE environment in the Portainer UI using the agent's LoadBalancer IP.

## Scripts

All scripts source `scripts/config.sh` for shared configuration and log output to `/tmp/$USER-portainer/`.

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
| `gke/start.sh` | Orchestrated rebuild (create + agents) |
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

## Environment Variables

Defined in `.envrc` (gitignored). See [.envrc.example](.envrc.example) for the template.

| Variable | Purpose |
|----------|---------|
| `AZURE_SUBSCRIPTION` | Azure subscription name or ID |
| `GCP_PROJECT` | GCP project ID for GKE cluster |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token (Zone:DNS:Edit) |
| `CLOUDFLARE_ZONE_ID` | Cloudflare zone ID for the domain |
| `TELEPORT_ACME_EMAIL` | Email for Let's Encrypt certificate notifications |

## Learning Path Progress

Following the [Rawkode Academy learning path](https://rawkode.academy/learning-paths/build-your-first-kubernetes-developer-platform) (~4.5 hours total):

| # | Module | Status |
|---|--------|--------|
| 1 | Hands-on Introduction to Portainer | Video watched |
| 2 | Hands-on Introduction to DevStand | Not started |
| 3 | Introduction to Crossplane | Not started |
| 4 | Crossplane in Action | Not started |
| 5 | Hands-on Introduction to Waypoint | Not started |
| 6 | Monitoring with Prometheus & Robusta | Not started |

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

Stop AKS when not in use: `./scripts/aks/stop.sh`. Delete GKE when not in use: `./scripts/gke/stop.sh` (GKE has no stop/start — use `./scripts/gke/start.sh` to rebuild).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
