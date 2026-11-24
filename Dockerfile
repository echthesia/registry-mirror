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

FROM docker.io/library/traefik:v3@sha256:a6c0194dda77bcb804824580f36fa7edc56e315b1acfe933366c8b52844a78a4 AS traefik
FROM docker.io/library/couchdb:3.4@sha256:d9b6609989f1d47822e84005946cecc2fd49e4be5e4f35da960d4379f6c60de0 AS couchdb
FROM ghcr.io/tecnativa/docker-socket-proxy:latest@sha256:be1ac64f33bd82043beb504822a17ba6b71668ea1ad7cf51a9a01d27bb7ab047 AS docker-socket-proxy
FROM docker.io/restic/rest-server:latest@sha256:5922067eb6f1ed8a632bc56101677ab4968a3b88a28806423e95ebb5eeecdebb AS rest-server
# Pinned one release behind (1.74.3) on purpose: the 1.74.4 digest was 5 days
# old at pin time, inside the 7-day soak. Dependabot refreshes it once aged.
FROM docker.io/rclone/rclone:latest@sha256:7cbeec24a44f206067597c0368be4de90ae19a64d5113c7d1938bd737a81e466 AS rclone

# Consumer: echthesia/infra (Quadlet units pull ghcr.io/echthesia/* with AutoUpdate=registry).
