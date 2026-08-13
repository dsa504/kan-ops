# GitHub Actions secrets (`dsa504/kan-ops`)

Set these under **Settings → Secrets and variables → Actions → New repository secret**.

## Build release workflow

[`build-release.yml`](../.github/workflows/build-release.yml) needs **no** repository secrets. It uses `GITHUB_TOKEN` to publish a Release.

Run it from **Actions → Build release → Run workflow**.

## Deploy workflow

[`deploy.yml`](../.github/workflows/deploy.yml) needs the secrets below. Same May First auth-grant + `sshpass` pattern as other NOLA/CC MF deploys.

| Secret | Example / notes |
|--------|------------------|
| `HOST` | `shell.mayfirst.org` |
| `USER` | `dsakan` |
| `PASSWORD` | Password for the `dsakan` hosting-order login (SSH + auth grant). Never commit. |
| `MAY_FIRST_AUTH_URL` | May First control-panel SSH **auth grant** endpoint URL (POST `user_name`, `user_pass`, `action=grant`). Copy from another working MF deploy repo’s Actions secrets if you already have one — do not paste the URL into git. |
| `KAN_APP_ROOT` | `/home/sites/388570/files/kan` (no trailing slash) |
| `SERVICE_NAME` | `red-item-388573.service` (Kan forever job item **388573**) |

Not secrets (already in repo / workflow env): public site URL, loopback port **3055**.

### Server `.env` (not a GitHub secret)

Postgres, `BETTER_AUTH_SECRET`, SMTP, etc. live in **`$KAN_APP_ROOT/.env` on the server** only. Deploy preserves that file (never overwrites it from CI).

### Suggested order

1. Set `HOST`, `USER`, `PASSWORD`, `MAY_FIRST_AUTH_URL`, `KAN_APP_ROOT`.
2. Run **Build release** once; confirm Release `kan-v0.6.0` + tarball asset.
3. Create server `.env` and the forever Scheduled Job; put `SERVICE_NAME` in GitHub secrets.
4. Run **Deploy** with release tag `kan-v0.6.0` (use **dry_run** first if you only want the upload).
5. Paste Apache ProxyPass when loopback health is green.
