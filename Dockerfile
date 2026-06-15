# NOT a buildable image. This file is a digest-pin MANIFEST that Dependabot
# tracks. Each FROM pins an upstream third-party image (at its multi-arch index
# digest) that we re-publish to ghcr.io/echthesia/* so noema can pull it with
# AutoUpdate=registry behind a supply-chain cooldown.
#
# Flow: Dependabot opens a same-tag digest-refresh PR when an upstream digest
# drifts (GA, because the digest is already pinned — no experiment needed), held
# back 7 days by the cooldown in .github/dependabot.yml. On merge,
# .github/workflows/mirror.yml `skopeo copy --all`s the merged digest to GHCR.
# The `AS <name>` is the destination image name (ghcr.io/echthesia/<name>:<tag>).
#
# Pinned at the live noema digests as of 2026-06-13, so flipping the noema units
# onto the mirror is a no-op. Never `docker build` this file.

FROM docker.io/library/traefik:v3@sha256:5809533c5b3fdfd961aa20af1cfbbc7d0e8ce3c4c3b1ee9acb0da00b7871c53b AS traefik
FROM docker.io/library/couchdb:3.4@sha256:4e84d4f460b104f890a3f55c655bfcedf0674bf8a0fe57029d13982134411ece AS couchdb
FROM ghcr.io/tecnativa/docker-socket-proxy:latest@sha256:1f3a6f303320723d199d2316a3e82b2e2685d86c275d5e3deeaf182573b47476 AS docker-socket-proxy

# Consumer: echthesia/infra (Quadlet units pull ghcr.io/echthesia/* with AutoUpdate=registry).
