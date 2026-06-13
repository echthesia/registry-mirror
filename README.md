# registry-mirror

Re-publishes a few third-party container images to `ghcr.io/echthesia/*` so that
[noema](https://github.com/echthesia/infra)'s Quadlet stack can pull them with
`AutoUpdate=registry` **behind a supply-chain cooldown** — getting hands-off
image deploys without auto-pulling a freshly-poisoned upstream image at day zero.

This repo holds only public image references and a copy workflow. It contains
nothing sensitive.

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
  to `ghcr.io/echthesia/<name>:<tag>`. Copies **by digest**, never by tag, so what
  ships is exactly what was soaked (no TOCTOU). Pushes with `GITHUB_TOKEN`.
- **`validate.yml`** — PR check: every pinned digest must resolve upstream. The
  required check that gates auto-merge.
- **`automerge.yml`** — enables auto-merge on Dependabot's PRs; the required
  check + the cooldown are the gates.

## Trust model

- The **7-day cooldown** is the supply-chain gate — it replaces a human reviewer
  (who can't meaningfully inspect a digest hash anyway), letting most compromised
  upstream images be caught and yanked before we mirror them.
- **`AutoUpdate=registry`** on noema is the constrained deploy primitive: it swaps
  the digest of the *same* image and rolls back on healthcheck failure; it cannot
  escalate privilege or change mounts/caps/image-name — so this is **not** a root
  code-execution path.
- Everything here runs on the built-in `GITHUB_TOKEN` — no PAT, no app, no runner.

Residual: a compromise of this repo's CI could push a bad image to GHCR that noema
would pull — but confined to the container's own privilege, never root.
