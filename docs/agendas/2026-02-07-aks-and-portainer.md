# Work Session Agenda - February 7, 2026 (Saturday)

## Resume Instructions

Resume the existing Claude Code session from yesterday:

```bash
claude --resume d70287cc-3061-463c-8cae-89d1ddcd06e8
```

Session name: `davidshaevel-portainer`

---

## Goal

Continue where we left off from the February 6 session. Create an AKS cluster, install Portainer BE, and explore the dashboard.

**Previous session completed:** Project setup (agenda items 1-2 from `2026-02-06-project-setup.md`)
**This session picks up at:** Agenda item 3 - Create AKS Cluster

---

## Agenda Items

### 1. Create AKS Cluster (TT-138)

- [ ] Decide on cluster configuration:
  - **Cluster name:** `portainer-aks`
  - **Node count:** 1 (minimize cost for learning)
  - **VM size:** `Standard_B2s` (~$30/month) or `Standard_DS2_v2` (~$47/month)
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

### 2. Install Portainer BE via Helm (TT-139)

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

### 3. Explore Portainer (TT-140)

- [ ] Tour the Portainer dashboard
- [ ] Review the local Kubernetes environment in Portainer
- [ ] Explore cluster resources through the Portainer UI
- [ ] Deploy a sample application through Portainer (optional)

### 4. Secure Access with Teleport (TT-141)

Following [Teleport Kubernetes Access](https://goteleport.com/docs/kubernetes-access/) and [Teleport Application Access](https://goteleport.com/docs/application-access/):

- [ ] Install Teleport on the AKS cluster (Helm chart)
- [ ] Configure Teleport Kubernetes agent for cluster access
- [ ] Register Portainer as a Teleport application (proxy to `https://portainer-svc:9443`)
- [ ] Switch Portainer service from LoadBalancer to ClusterIP (remove public exposure)
- [ ] Configure Teleport users/roles
- [ ] Update scripts and documentation

### 5. Document & Commit

- [ ] Update CLAUDE.md with any architecture changes
- [ ] Update CLAUDE.local.md session notes with what was accomplished
- [ ] Update learning path progress table in CLAUDE.md
- [ ] Commit and push all changes
- [ ] Update Linear issues (TT-138, TT-139, TT-140, TT-141) with completion status

### 6. Cost Awareness

**Remember to stop the cluster when done for the day:**
```bash
az aks stop --resource-group portainer-rg --name portainer-aks
```

**Restart when needed:**
```bash
az aks start --resource-group portainer-rg --name portainer-aks
```

---

## References

- [Portainer BE Install Docs (K8s Baremetal)](https://docs.portainer.io/start/install/server/kubernetes/baremetal)
- [Azure AKS Quickstart](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-cli)
- [AKS Start/Stop Cluster](https://learn.microsoft.com/en-us/azure/aks/start-stop-cluster)
- [Teleport Kubernetes Access](https://goteleport.com/docs/kubernetes-access/)
- [Teleport Application Access](https://goteleport.com/docs/application-access/)
- Previous agenda: `docs/agendas/2026-02-06-project-setup.md`
