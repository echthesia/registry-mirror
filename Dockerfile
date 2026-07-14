# NOT a buildable image. This file is a digest-pin MANIFEST that Dependabot
# tracks. Each FROM pins an upstream third-party image (at its multi-arch index
# digest) that we re-publish to ghcr.io/echthesia/* so noema can pull it with
# AutoUpdate=registry behind a supply-chain cooldown.
#
# Flow: Dependabot opens a same-tag digest-refresh PR when an upstream digest
# drifts (GA, because the digest is already pinned — no experiment needed), held
# back 7 days by the cooldown in .github/dependabot.yml. When the required
# `validate` check passes the PR auto-merges, and .github/workflows/mirror.yml
# (triggered via workflow_run on validate) `skopeo copy --all`s the merged digest
# to GHCR. NB it triggers on validate, not on the merge push: an auto-merge push
# is made with GITHUB_TOKEN, which by GitHub's anti-recursion rule does not fire
# push-triggered workflows. The `AS <name>` is the destination image name
# (ghcr.io/echthesia/<name>:<tag>).
#
# Pinned at the live noema digests as of 2026-06-13, so flipping the noema units
# onto the mirror is a no-op. Never `docker build` this file.

FROM docker.io/library/traefik:v3@sha256:6608e0f4b12983a2e9874f5dac86105bd449b59067b6806350a030216aebf393 AS traefik
FROM docker.io/library/couchdb:3.4@sha256:b1d84a34afba114d6e9f4fe3fad210e60eaaadab8fd9cd1d218d7d2cad663874 AS couchdb
FROM ghcr.io/tecnativa/docker-socket-proxy:latest@sha256:1f3a6f303320723d199d2316a3e82b2e2685d86c275d5e3deeaf182573b47476 AS docker-socket-proxy
FROM docker.io/restic/rest-server:latest@sha256:d2aff06f47eb38637dff580c3e6bce4af98f386c396a25d32eb6727ec96214a5 AS rest-server
# Pinned one release behind (1.74.3) on purpose: the 1.74.4 digest was 5 days
# old at pin time, inside the 7-day soak. Dependabot refreshes it once aged.
FROM docker.io/rclone/rclone:latest@sha256:623378ad0ff3ebd5cebf77720843c0e02edfe46e2d5b5ac6bed54c6371780dfb AS rclone

# Consumer: echthesia/infra (Quadlet units pull ghcr.io/echthesia/* with AutoUpdate=registry).
