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
