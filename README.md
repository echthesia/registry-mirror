# registry-mirror

Re-publishes a few third-party container images to `ghcr.io/echthesia/*` so that
[noema](https://github.com/echthesia/infra)'s Quadlet stack can pull them with
`AutoUpdate=registry` behind a supply-chain cooldown.

## How it works

```
upstream (docker.io/traefik:v3@sha256:…)
   │  Dependabot opens a same-tag digest-refresh PR when the digest drifts,
   │  held back 7 days by the cooldown (.github/dependabot.yml)
   ▼
[ PR ] ──validate (digest resolves) ──► auto-merge
   │  on merge, mirror.yml: skopeo copy --all BY DIGEST
   ▼
ghcr.io/echthesia/traefik:v3   (a moving tag, but only this repo moves it)
   │  noema: podman-auto-update.timer pulls it, healthcheck rollback as the net
   ▼
noema unit: Image=ghcr.io/echthesia/traefik:v3  +  AutoUpdate=registry
```

- **`Dockerfile`** — a digest-pin *manifest* (not a buildable image). Each `FROM`
  pins an upstream image at its multi-arch index digest. `AS <name>` is the
  destination image name.
- **`.github/dependabot.yml`** — `docker` ecosystem, `cooldown.default-days: 7`.
  `ignore`s all semver tag bumps so the mirror stays on the pinned tag and only
  refreshes its digest; tag/major upgrades (e.g. traefik `v3 → v4`) are manual.
- **`mirror.yml`** — on a merge to `main`, `skopeo copy --all` each pinned digest
  to `ghcr.io/echthesia/<name>:<tag>`. Pushes with `GITHUB_TOKEN`.
- **`validate.yml`** — PR check: every pinned digest must resolve upstream.
- **`automerge.yml`** — enables auto-merge on Dependabot's PRs.
- **`scan.yml`** — daily trivy scan of the pinned (deployed) digests;
  maintains a single tracking issue for fixable HIGH/CRITICAL CVEs, and runs
  the cooldown override (below).

## Urgent patches

The 7-day cooldown deliberately trades patch latency for soak time. Two ways
around it when the deployed digest has a serious fixable CVE:

- **Automatic (cooldown override, in `scan.yml`)**: when the upstream tag's
  current digest fixes at least one of the deployed digest's fixable
  HIGH/CRITICAL CVEs *and* is itself ≥24h old (shortened soak), the scan opens
  the same-tag digest-bump PR itself, auto-merged behind the required
  `validate` check, then dispatches `mirror`. This mirrors Dependabot's
  "security updates bypass the cooldown" semantics, which Dependabot does not
  offer for docker digest pins. Notification lands in the tracking issue; a
  Buzzer push is planned once noema's 443/edge gates reopen (senders outside
  the tailnet can't reach the relay today).
- **Manual fast-track**: edit the `FROM` pin to the fixed digest yourself, PR,
  merge on green `validate` — `mirror.yml` publishes on merge. Useful when the
  fix matters but trivy can't see it (e.g. not in the vuln DB yet) or you
  don't want to wait out the shortened soak.

If GHCR ever looks stale relative to a merged pin (the `workflow_run` trigger
lost a race), `gh workflow run mirror.yml` is idempotent catch-up.

## Signing

After each copy, `mirror.yml` signs the mirrored digest with the shared
echthesia cosign key (`COSIGN_PRIVATE_KEY` / `COSIGN_PASSWORD` Actions
secrets; archival copy in the infra repo's `secrets/cosign.sops.yaml`). noema's
`/etc/containers/policy.json` (echthesia/infra, `roles/quadlet`) rejects
unsigned `ghcr.io/echthesia/*` pulls, so the signature is what marks a digest
as "went through this pipeline" — it says nothing about upstream provenance
beyond the digest pin itself. Re-runs skip digests already signed by our key.
