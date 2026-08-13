# kan-ops

Ops repo for self-hosting [Kan](https://github.com/kanbn/kan) on **May First** for **New Orleans DSA**, with a pattern other Cooperative Codebase projects can copy later.

This repository pins an upstream Kan release tag, builds a **Next.js standalone tarball on GitHub-hosted runners**, and deploys that artifact to May First over SSH. May First only unpacks, runs Postgres migrations, and starts Node via a forever systemd job behind Apache.

## Architecture (short)

1. **Build (GitHub Actions, `ubuntu-latest`):** checkout Kan @ `KAN_VERSION` → `pnpm` build with `NEXT_PUBLIC_USE_STANDALONE_OUTPUT=true` → pack `kan-standalone-<version>.tar.gz` → GitHub Release asset.
2. **Deploy (GitHub Actions → May First SSH):** download Release → sync to site files → unpack → migrate → restart forever job → healthcheck.
3. **Runtime (May First):** Apache HTTPS → `ProxyPass` → `127.0.0.1:<port>` → Node (foreground via forever job) → Postgres (MF control panel).

**Do not run `next build` / heavy `pnpm` builds on May First** (or on shared Forgejo / `mayfirst-ci` runners). Those environments commonly OOM on Next.js. Docker/Compose are unavailable on May First shared hosting.

Hostname target: `https://kan.dsaneworleans.org` (changeable later).

**May First:** one web site per hosting order. Kan uses a **dedicated hosting order** under the New Orleans DSA membership (not a second site on an existing order). See [`docs/may-first-checklist.md`](./docs/may-first-checklist.md).

## Docs

| Doc | What |
|-----|------|
| [`docs/may-first-checklist.md`](./docs/may-first-checklist.md) | Human MF control-panel steps (site, DNS, TLS, Postgres, Apache, forever job) |
| [`docs/access-model.md`](./docs/access-model.md) | Email-invite-only auth (shipping), optional invite-link risk, bootstrap |
| [`docs/github-secrets.md`](./docs/github-secrets.md) | GitHub Actions secrets + which workflows need them |

## Auth (MVP)

**Email-invite-only first:** credentials on, public signup off (`NEXT_PUBLIC_DISABLE_SIGN_UP=true`), SMTP on; admins invite from Members by email. A Discord workspace invite link is optional later and has residual `/signup` risk on Kan v0.6.0 — see [`docs/access-model.md`](./docs/access-model.md).

SMTP uses an existing Proton mailbox already used for chapter automation (no new mailbox for MVP). Prefer a From display name like `NOLA DSA Kan <…>`.

## License — AGPL

Kan is licensed under **AGPL-3.0**. Prefer pinning **unmodified** upstream via `KAN_VERSION`. If we modify Kan and serve it to users, we must offer that corresponding source (a public fork is the usual approach).

This ops repo’s scripts, Apache snippets, and workflows are ours. They are separate from Kan’s license surface; Kan itself remains AGPL wherever it runs.

## CI / deploy

| Workflow | When | Secrets |
|----------|------|---------|
| **Build release** | `workflow_dispatch` or pin/script changes | None (`GITHUB_TOKEN` only) |
| **Deploy** | `workflow_dispatch` (release tag) | See [`docs/github-secrets.md`](./docs/github-secrets.md) |

## Secrets

Never commit `.env`, mailbox passwords, Discord tokens, or May First credentials. Put secrets only in the server `.env` and GitHub Actions secrets (list in [`docs/github-secrets.md`](./docs/github-secrets.md)).

## Cooperative Codebase (reuse)

**CC interactive runbook (canonical for the next setup session):**  
`cooperative-codebase/infrastructure/docs/KAN_MAY_FIRST_SETUP.md` on the CC infrastructure repo (Forgejo: `cooperative-codebase/infrastructure`).  
Agents: walk the human through it and **update that doc’s Outcomes / Apache companions as you go**.

Pattern summary:

1. **Copy or mirror this repo** (do not thin-fork Kan unless you must modify the app).
2. **Build stays on GitHub-hosted runners** (`ubuntu-latest`). Do **not** run `pnpm build` / Next production builds on May First or on Forgejo / `mayfirst-ci` runners (OOM).
3. Forgejo may later run a **deploy-only** job (auth grant + rsync/SSH + restart) that consumes a GitHub Release tarball — it should not rebuild Next.
4. Create a **new May First hosting order** (one site per order), new Postgres, new forever job, new loopback port, new Apache ProxyPass snippet, new server `.env`, and new GitHub Actions secrets (`HOST` / `USER` / `PASSWORD` / `MAY_FIRST_AUTH_URL` / `KAN_APP_ROOT` / `SERVICE_NAME`).
5. Pin upstream via `KAN_VERSION`; bump the pin and re-run **Build release** → **Deploy** to upgrade.
6. **Rollback:** keep prior `releases/<id>/` dirs (deploy prunes old ones); point `current` at a previous release and restart the forever unit, or re-run **Deploy** with an older Release tag.

## Status

NOLA DSA Kan is live at `https://kan.dsaneworleans.org` with CI build/deploy and email-invite-only auth. See checklists for host-specific IDs.
