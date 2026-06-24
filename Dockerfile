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

FROM docker.io/library/traefik:v3@sha256:e4d98158c01ad752fc1071d4e9573788747230d902cdde00a772516e692d07c9 AS traefik
FROM docker.io/library/couchdb:3.4@sha256:b1d84a34afba114d6e9f4fe3fad210e60eaaadab8fd9cd1d218d7d2cad663874 AS couchdb
FROM ghcr.io/tecnativa/docker-socket-proxy:latest@sha256:1f3a6f303320723d199d2316a3e82b2e2685d86c275d5e3deeaf182573b47476 AS docker-socket-proxy

# Consumer: echthesia/infra (Quadlet units pull ghcr.io/echthesia/* with AutoUpdate=registry).
