# Work Agenda: Kubernetes Developer Platform

**Date:** 2026-02-16
**Constraint:** At most 3 parallel Claude Code sessions per wave
**Related:** [Kubernetes Developer Platform](https://linear.app/davidshaevel-dot-com/project/kubernetes-developer-platform-7d0ec7112089)

## Dependency Graph

```
TT-152 (Repo setup)
├── TT-153 (ACR)
├── TT-154 (Argo CD) ←── CRITICAL PATH
│   └── TT-156 (Crossplane) ←── CRITICAL PATH
│       ├── TT-157 (DevStand)
│       └── TT-159 (EKS)
├── TT-155 (Cilium)
│   └── TT-158 (Monitoring) ←── also blocked by TT-152
│       └── TT-163 (Loki)
├── TT-160 (Rename ECS)
├── TT-161 (Archive)
└── TT-162 (ESO)
```

**Critical path:** TT-152 → TT-154 → TT-156 → TT-157/TT-159
**Secondary path:** TT-152 → TT-155 → TT-158 → TT-163

---

## Wave 1: Foundation (1 session)

Everything is blocked by this. Must complete before any parallelism is possible.

| Session | Issues | Priority | Est. Size |
|---------|--------|----------|-----------|
| A | **TT-152** — Repo setup and migration | High | Large |

**What gets done:**
- Create `davidshaevel-k8s-platform` repo with bare + worktree structure
- Copy scripts, workflows, configs, design docs from davidshaevel-portainer
- Update `config.sh` with new names (`k8s-developer-platform-rg` / `k8s-developer-platform-aks`)
- Create AKS cluster with Azure CNI Overlay + Cilium
- Install Portainer BE, Teleport CE, configure Cloudflare DNS
- Create Azure service principal, configure GitHub secrets
- Verify AKS/GKE lifecycle workflows

**Manual steps (pause points):** Portainer license key, Teleport admin + MFA

**Unblocks:** 6 issues (TT-153, TT-154, TT-155, TT-160, TT-161, TT-162)

---

## Wave 2: Core Platform Services (3 parallel sessions)

Six issues unblock after Wave 1. Grouped into 3 sessions, prioritizing the critical path and the monitoring path.

| Session | Issues | Priority | Est. Size |
|---------|--------|----------|-----------|
| A | **TT-154** — Argo CD | High | Medium |
| B | **TT-153** — ACR + **TT-160** — Rename ECS platform | High + Medium | Medium + Small |
| C | **TT-155** — Cilium/Hubble + **TT-162** — ESO | Medium + Medium | Medium + Medium |

**Session A (critical path):** Install Argo CD on AKS, register in Teleport, create app manifests for existing platform components, establish GitOps workflow.

**Session B:** Create ACR, build/replication workflows, configure AKS pull credentials. Then rename `davidshaevel-platform` → `davidshaevel-ecs-platform` (quick GitHub operation).

**Session C:** Enable Hubble, define network policies, install Hubble UI. Then create Azure Key Vault, install ESO, configure `ClusterSecretStore`, migrate hardcoded secrets to Key Vault + `ExternalSecret` resources. Both are AKS installs in separate namespaces (`cilium` and `external-secrets`) — no conflicts.

**Why TT-161 (Archive) is deferred:** Better to verify the new platform works across more phases before archiving the source repo.

**Unblocks:** TT-156 (needs TT-154), TT-158 (needs TT-152 + TT-155)

---

## Wave 3: Infrastructure & Observability (3 parallel sessions)

| Session | Issues | Priority | Est. Size |
|---------|--------|----------|-----------|
| A | **TT-156** — Crossplane | Medium | Large |
| B | **TT-158** — Prometheus + Grafana + Alertmanager | Medium | Medium |
| C | **TT-161** — Archive davidshaevel-portainer | Medium | Small |

**Session A (critical path):** Install Crossplane, install GCP/AWS/Azure providers, configure `ProviderConfig` credentials, create XRDs + compositions + claims for GKE/EKS/Azure clusters, replace gcloud commands with Crossplane claims in GKE lifecycle workflows.

**Session B:** Install kube-prometheus-stack, configure Grafana dashboards, register Grafana in Teleport, set up alerting rules, configure Prometheus to scrape Cilium/Hubble metrics.

**Session C:** Verify migration is complete, update davidshaevel-portainer README to point to new repo, archive on GitHub, update Linear/portfolio references. This is small — session can assist with A or B after completing.

**Unblocks:** TT-157 (needs TT-156), TT-159 (needs TT-156), TT-163 (needs TT-158)

---

## Wave 4: Extensions (3 parallel sessions)

All remaining issues are unblocked and fully independent.

| Session | Issues | Priority | Est. Size |
|---------|--------|----------|-----------|
| A | **TT-157** — DevStand | Medium | Medium |
| B | **TT-159** — EKS lifecycle | Low | Large |
| C | **TT-163** — Grafana Loki | Medium | Medium |

**Session A:** Install DevStand on AKS, configure service catalog, integrate with Crossplane for self-service environment provisioning.

**Session B:** Create EKS cluster Crossplane composition, add EKS lifecycle workflows, set up ACR → ECR replication, install platform agents (Portainer, Teleport, Cilium, ESO) on EKS. Largest remaining task.

**Session C:** Install Grafana Loki + Promtail, configure Grafana data source, set up log retention, create LogQL dashboards.

---

## Summary

| Wave | Sessions | Issues | Cumulative Complete |
|------|----------|--------|---------------------|
| 1 | 1 | TT-152 | 1/12 |
| 2 | 3 | TT-153, TT-154, TT-155, TT-160, TT-162 | 6/12 |
| 3 | 3 | TT-156, TT-158, TT-161 | 9/12 |
| 4 | 3 | TT-157, TT-159, TT-163 | 12/12 |

**Total session-slots:** 10 (across 4 waves)
**Critical path sessions:** Wave 1 (TT-152) → Wave 2A (TT-154) → Wave 3A (TT-156) → Wave 4A/B (TT-157 or TT-159)

The critical path determines the minimum number of sequential waves regardless of parallelism. Every wave has the critical-path issue in Session A.
