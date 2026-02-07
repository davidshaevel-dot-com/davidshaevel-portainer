# Portainer on Azure Kubernetes

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
    |       |       Web UI:   https://teleport.davidshaevel.com
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
```

All traffic flows through Teleport. Portainer has no public endpoint.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Cloud | Azure (AKS, Resource Groups) |
| Container Orchestration | Kubernetes (AKS) |
| Platform Management | Portainer Business Edition |
| Secure Access | Teleport Community Edition (self-hosted) |
| DNS | Cloudflare (API-managed) |
| TLS | Let's Encrypt (ACME via Teleport) |
| IaC | Azure CLI, Helm |

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- [jq](https://jqlang.github.io/jq/download/)
- An Azure subscription
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
   ./scripts/aks-create.sh
   ```

4. **Install Portainer:**

   ```bash
   ./scripts/portainer-install.sh
   ```

5. **Install Teleport and configure DNS:**

   ```bash
   ./scripts/teleport-install.sh
   ./scripts/teleport-dns.sh
   ```

6. **Deploy the Teleport agent** (registers Portainer app and Kubernetes cluster):

   ```bash
   ./scripts/teleport-agent-install.sh
   ```

   This also switches Portainer from LoadBalancer to ClusterIP.

## Scripts

All scripts source `scripts/config.sh` for shared configuration and log output to `/tmp/$USER-portainer/`.

### AKS Cluster

| Script | Description |
|--------|-------------|
| `scripts/aks-create.sh` | Create the AKS cluster |
| `scripts/aks-delete.sh` | Delete the AKS cluster |
| `scripts/aks-start.sh` | Start a stopped cluster |
| `scripts/aks-stop.sh` | Stop the cluster (save costs) |
| `scripts/aks-status.sh` | Show cluster status |
| `scripts/aks-credentials.sh` | Fetch kubeconfig credentials |

### Portainer

| Script | Description |
|--------|-------------|
| `scripts/portainer-install.sh` | Install Portainer BE via Helm |
| `scripts/portainer-uninstall.sh` | Uninstall Portainer |
| `scripts/portainer-status.sh` | Show Portainer deployment status |

### Teleport

| Script | Description |
|--------|-------------|
| `scripts/teleport-install.sh` | Install Teleport Community Edition via Helm |
| `scripts/teleport-uninstall.sh` | Uninstall Teleport |
| `scripts/teleport-status.sh` | Show Teleport deployment status |
| `scripts/teleport-dns.sh` | Create/update Cloudflare DNS records (A + wildcard) |
| `scripts/teleport-dns-delete.sh` | Delete Cloudflare DNS records |
| `scripts/teleport-agent-install.sh` | Deploy Teleport agent + switch Portainer to ClusterIP |
| `scripts/teleport-agent-uninstall.sh` | Remove agent + restore Portainer LoadBalancer |

## Environment Variables

Defined in `.envrc` (gitignored). See [.envrc.example](.envrc.example) for the template.

| Variable | Purpose |
|----------|---------|
| `AZURE_SUBSCRIPTION` | Azure subscription name or ID |
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
| Standard_B2s node (1x) | ~$30 |
| Load Balancer (Teleport) | ~$18 |
| Managed Disks (PVs) | ~$1-5 |
| **Total** | **~$50-55** |

Stop the cluster when not in use to save costs: `./scripts/aks-stop.sh`

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
