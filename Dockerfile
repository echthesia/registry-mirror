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

FROM docker.io/library/traefik:v3@sha256:5203c3f39ca70de6790d964624e042463ffbd57715bc82be155cf224c0dd5144 AS traefik
FROM docker.io/library/couchdb:3.4@sha256:91ca7a6482e079ce74ebcf7aae3493ebbffd59916f6c232ecee3ab686d9fa3f0 AS couchdb
FROM ghcr.io/tecnativa/docker-socket-proxy:latest@sha256:1f5038b54f06c3e18422902cf00ba21803d1c97805aae032e5e6673d532d3459 AS docker-socket-proxy
FROM docker.io/restic/rest-server:latest@sha256:d2aff06f47eb38637dff580c3e6bce4af98f386c396a25d32eb6727ec96214a5 AS rest-server
# Pinned one release behind (1.74.3) on purpose: the 1.74.4 digest was 5 days
# old at pin time, inside the 7-day soak. Dependabot refreshes it once aged.
FROM docker.io/rclone/rclone:latest@sha256:b06aed988cf5967de7c25be5925240983981c757f4ed1ac9d2fa659d51d60548 AS rclone

# Consumer: echthesia/infra (Quadlet units pull ghcr.io/echthesia/* with AutoUpdate=registry).
