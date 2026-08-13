# GitHub Actions secrets (`dsa504/kan-ops`)

Set these under **Settings → Secrets and variables → Actions → New repository secret**.

## Build release workflow

[`build-release.yml`](../.github/workflows/build-release.yml) needs **no** repository secrets. It uses `GITHUB_TOKEN` to publish a Release.

Run it from **Actions → Build release → Run workflow**.

The tarball is **site-agnostic**: CI does not set `NEXT_PUBLIC_BASE_URL` or chapter `NEXT_PUBLIC_STORAGE_*`. One Release asset can be deployed to NOLA DSA, Cooperative Codebase, etc.; each site’s forever-job `.env` supplies public URLs at runtime.

## Deploy workflow

[`deploy.yml`](../.github/workflows/deploy.yml) needs the secrets below. Same May First auth-grant + `sshpass` pattern as other NOLA/CC MF deploys.

| Secret | Example / notes |
|--------|------------------|
| `HOST` | `shell.mayfirst.org` |
| `USER` | `dsakan` |
| `PASSWORD` | Password for the `dsakan` hosting-order login (SSH + auth grant). Never commit. |
| `MAY_FIRST_AUTH_URL` | May First control-panel SSH **auth grant** endpoint URL (POST `user_name`, `user_pass`, `action=grant`). Copy from another working MF deploy repo’s Actions secrets if you already have one — do not paste the URL into git. |
| `KAN_APP_ROOT` | `/home/sites/388570/files/kan` (absolute, **no trailing slash**, no quotes) |
| `SERVICE_NAME` | `red-item-388573.service` (Kan forever job item **388573**) |

Not secrets (already in repo / workflow env): public site URL, loopback port **3055**.

### Server `.env` (not a GitHub secret)

Lives in **`$KAN_APP_ROOT/.env` on the server** only. Deploy preserves that file (never overwrites it from CI).

**Required for every chapter (runtime, not in the Release):**

- `NEXT_PUBLIC_BASE_URL` — e.g. NOLA `https://kan.dsaneworleans.org`; CC `https://kan.cooperativecodebase.com`
- Plus Postgres, `BETTER_AUTH_SECRET`, SMTP, `PORT`, auth flags, etc. (see [`.env.example`](../.env.example))
- When using S3/uploads: `NEXT_PUBLIC_STORAGE_URL`, `NEXT_PUBLIC_STORAGE_DOMAIN`, bucket names (CC may use `https://s3.cooperativecodebase.com`)

### Suggested order

1. Set `HOST`, `USER`, `PASSWORD`, `MAY_FIRST_AUTH_URL`, `KAN_APP_ROOT`.
2. Run **Build release** once; confirm Release `kan-v0.6.0` + tarball asset (generic).
3. Create server `.env` (including `NEXT_PUBLIC_BASE_URL`) and the forever Scheduled Job; put `SERVICE_NAME` in GitHub secrets.
4. Run **Deploy** with release tag `kan-v0.6.0` (use **dry_run** first if you only want the upload).
5. Paste Apache ProxyPass when loopback health is green.
6. Smoke: open the chapter origin; confirm runtime env (e.g. view `/__ENV.js` or page network) shows **this** chapter’s `NEXT_PUBLIC_BASE_URL`, not another host and not empty.

### After a new generic Release (NOLA)

1. Confirm `$KAN_APP_ROOT/.env` still has `NEXT_PUBLIC_BASE_URL=https://kan.dsaneworleans.org`.
2. Actions → **Deploy** → tag `kan-v0.6.0` (or the new `kan-v*` tag) → run (not dry-run).
3. Smoke `https://kan.dsaneworleans.org/login` — loads; no redirects/links to `example.invalid` or another chapter; `/__ENV.js` matches NOLA base URL; email-invite auth still OK.
