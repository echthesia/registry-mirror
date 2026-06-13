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

FROM docker.io/library/traefik:v3@sha256:d6858791f9e74df44ca4014166647c41cdc2abd3bf2a71b832ca4e1c6a91b257 AS traefik
FROM docker.io/library/couchdb:3.4@sha256:af9d39a66d53cbf1cfe53ff20fb093e426f7c09a90d15585e13b028d490a7f08 AS couchdb
FROM ghcr.io/tecnativa/docker-socket-proxy:latest@sha256:1f3a6f303320723d199d2316a3e82b2e2685d86c275d5e3deeaf182573b47476 AS docker-socket-proxy
