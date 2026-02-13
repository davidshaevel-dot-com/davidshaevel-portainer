# Postmortem: GKE Start Workflow Failures

**Date:** 2026-02-13
**Duration:** 12 attempts over ~6 hours
**Severity:** Build/deploy automation (non-production)
**Related issue:** [TT-151](https://linear.app/davidshaevel-dot-com/issue/TT-151/add-github-actions-workflows-for-cluster-lifecycle)
**Status:** Resolved

## Summary

The GKE Start GitHub Actions workflow failed 11 consecutive times before succeeding on attempt 12. The failures spanned IAM permissions, Portainer API integration, TLS certificate verification, and Kubernetes pod readiness. The root cause of the most persistent failure (attempts 7-12) was Portainer's TLS certificate verification during agent endpoint creation via the REST API.

## Impact

- No production impact (automation for dev/portfolio infrastructure)
- ~6 hours of debugging time
- 11 GKE clusters created and deleted (each auto-cleaned on failure, so no cost leak)

## Root Cause

The Portainer Agent auto-generates a self-signed TLS certificate using the **pod IP** as the Subject Alternative Name (SAN). When Portainer server creates an Agent endpoint via `POST /api/endpoints`, it pings `https://<AGENT_IP>:9001/ping` to verify connectivity. Since the agent is reached via the GKE **LoadBalancer IP** (which differs from the pod IP), TLS certificate verification fails:

```
x509: certificate is valid for 10.52.0.12, not 34.134.70.44
```

This is a known issue in the Portainer API ([#10201](https://github.com/portainer/portainer/issues/10201), [#12470](https://github.com/portainer/portainer/issues/12470)). The GUI handles this correctly, but the API requires explicit TLS configuration.

## Resolution

All three TLS form fields must be set together in the endpoint creation request:

```bash
curl -sk -X POST "${PORTAINER_BASE_URL}/api/endpoints" \
    -F "Name=GKE" \
    -F "EndpointCreationType=2" \
    -F "URL=tcp://${AGENT_IP}:9001" \
    -F "TLS=true" \
    -F "TLSSkipVerify=true" \
    -F "TLSSkipClientVerify=true" \
    -F "GroupID=1"
```

- `TLS=true` — tells Portainer to create a TLS configuration (required for the skip flags to take effect)
- `TLSSkipVerify=true` — sets `InsecureSkipVerify: true`, bypassing server cert validation
- `TLSSkipClientVerify=true` — skips client cert requirement, preventing "Invalid certificate file" errors

All three are required. Omitting any one causes a different failure mode.

## Timeline of All Failures

| Attempt | Step | Error | Fix |
|---------|------|-------|-----|
| 1-2 | Create GKE Cluster | `PERMISSION_DENIED: Permission denied to enable service [container.googleapis.com]` | Skip API enable in CI — the API is already enabled, and the GCP service account lacks `serviceusage.services.enable` permission |
| 3 | Create GKE Cluster | `The user does not have access to service account "...-compute@developer.gserviceaccount.com"` | Grant `roles/iam.serviceAccountUser` to the GCP service account |
| 4 | Install Portainer Agent | `AuthorizationFailed` reading public IP from `MC_portainer-rg_portainer-aks_eastus` | Grant Azure SP Contributor role on the AKS-managed infrastructure resource group |
| 5 | Register GKE in Portainer | `Unable to remove TLS CA file from disk` | Switch from PUT (update-in-place) to DELETE + POST (delete-then-recreate) |
| 6 | Register GKE in Portainer | `Invalid environment name` / `Invalid request payload` | Switch from JSON body (`-d`) to multipart form data (`-F`) — the endpoint requires `multipart/form-data` |
| 7 | Register GKE in Portainer | `Invalid certificate file` | Removed `TLS=true` (incomplete fix — needed all 3 TLS flags together) |
| 8 | Register GKE in Portainer | `context deadline exceeded` | Moved LoadBalancer source restriction to after registration (new `gke-agent-restrict-lb.sh` script) |
| 9 | Register GKE in Portainer | `context deadline exceeded` (6 retries) | Added retry loop (6 attempts x 15s = 90s) — revealed the real error was TLS, not timeout |
| 10 | Register GKE in Portainer | `x509: certificate is valid for 10.36.0.12, not 34.60.17.183` | Added `TLSSkipVerify=true` form field — not respected without `TLS=true` |
| 11 | Install Portainer Agent | `no matching resources found` from `kubectl wait` | Changed `kubectl wait --for=condition=ready pod` to `kubectl rollout status deployment` |
| 12 | All steps | **Success** | Added `TLS=true` + `TLSSkipVerify=true` + `TLSSkipClientVerify=true` together |

## What Went Wrong

1. **Portainer API documentation gaps** — The API does not clearly document that `TLS=true` is required for `TLSSkipVerify` to take effect, or that `TLSSkipClientVerify` is needed to avoid certificate file upload requirements.

2. **Misleading `--tlsskipverify` server flag** — The Portainer `--tlsskipverify` container arg only applies to the server's own connections (e.g., Docker API via `-H`), not to dynamically created agent endpoints. This led to a false fix in attempt 10-11.

3. **IAM permissions were under-scoped** — The Azure SP and GCP SA were created with minimal permissions that proved insufficient. AKS creates a managed resource group (`MC_*`) that also needs access, and GKE cluster creation requires `iam.serviceAccountUser` on the default compute service account.

4. **Error masking** — The `context deadline exceeded` error in attempts 8-9 masked the underlying TLS error. Only after adding retries did the actual x509 error surface.

## Lessons Learned

1. **Test API calls locally first** — Port-forwarding to Portainer and testing `curl` commands locally would have caught the TLS issue faster than iterating through full workflow runs.

2. **Read the source code, not just docs** — The Portainer source code at `api/crypto/tls.go` clearly shows that `TLS=true` gates the entire TLS configuration. The docs don't explain this.

3. **Scope IAM permissions generously for CI, then tighten** — Starting with broader permissions and narrowing down is faster than discovering missing permissions one at a time across 4 failed runs.

4. **Retry loops surface real errors** — The initial timeout masked the TLS error. Adding retries with logged responses was essential for diagnosis.

## Action Items

- [x] Fix `gke-agent-register.sh` with all 3 TLS form fields
- [x] Update `create-azure-sp.sh` to include MC_ resource group scope
- [x] Update `create-gcp-sa.sh` to include `iam.serviceAccountUser` role
- [x] Add `gke-agent-restrict-lb.sh` as a separate post-registration step
- [x] Use `kubectl rollout status` instead of `kubectl wait` for agent readiness
