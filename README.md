# kan-ops

Ops repo for self-hosting [Kan](https://github.com/kanbn/kan) on **May First** for **New Orleans DSA**, with a pattern other Cooperative Codebase projects can copy later.

This repository pins an upstream Kan release tag, builds a **Next.js standalone tarball on GitHub-hosted runners**, and deploys that artifact to May First over SSH. May First only unpacks, runs Postgres migrations, and starts Node via a forever systemd job behind Apache.

## Architecture (short)

1. **Build (GitHub Actions, `ubuntu-latest`):** checkout Kan @ `KAN_VERSION` → `pnpm` build with `NEXT_PUBLIC_USE_STANDALONE_OUTPUT=true` → pack `kan-standalone-<version>.tar.gz` → GitHub Release asset.
2. **Deploy (GitHub Actions → May First SSH):** download Release → sync to site files → unpack → migrate → restart forever job → healthcheck.
3. **Runtime (May First):** Apache HTTPS → `ProxyPass` → `127.0.0.1:<port>` → Node (foreground via forever job) → Postgres (MF control panel).

**Do not run `next build` / heavy `pnpm` builds on May First** (or on shared Forgejo / `mayfirst-ci` runners). Those environments commonly OOM on Next.js. Docker/Compose are unavailable on May First shared hosting.

Hostname target: `https://kan.dsaneworleans.org` (changeable later).

## Docs

| Doc | What |
|-----|------|
| [`docs/may-first-checklist.md`](./docs/may-first-checklist.md) | Human MF control-panel steps (site, DNS, TLS, Postgres, Apache, forever job) |
| [`docs/access-model.md`](./docs/access-model.md) | Invite-link auth (shipping), bootstrap admin, how to open signup later |

## Auth (MVP)

**Invite-link model:** credentials on, public signup off, SMTP on; workspace invite link in a members-only Discord channel. Rotate the link if it leaks. See [`docs/access-model.md`](./docs/access-model.md).

SMTP uses an existing Proton mailbox already used for chapter automation (no new mailbox for MVP). Prefer a From display name like `NOLA DSA Kan <…>`.

## License — AGPL

Kan is licensed under **AGPL-3.0**. Prefer pinning **unmodified** upstream via `KAN_VERSION`. If we modify Kan and serve it to users, we must offer that corresponding source (a public fork is the usual approach).

This ops repo’s scripts, Apache snippets, and workflows are ours. They are separate from Kan’s license surface; Kan itself remains AGPL wherever it runs.

## Secrets

Never commit `.env`, mailbox passwords, Discord tokens, or May First credentials. Put secrets only in the server `.env` and GitHub Actions secrets.

## Status

Automate CI/CD first, then go live — no long-lived manual deploy path.
