# May First checklist — Kan (`kan.dsaneworleans.org`)

Human steps in the May First members control panel and on the site SSH account. Do **not** apply production-adjacent changes without confirmation from the operator.

Control panel: https://members.mayfirst.org/cp/

Official guides:

- [How to add a web site](https://help.mayfirst.org/en/guide/how-to-add-web-site)
- [DNS records](https://help.mayfirst.org/en/guide/how-to-create-web-dns-record)
- [systemd / forever web service](https://help.mayfirst.org/en/guide/how-to-use-a-systemd-service-to-run-web-app)
- [SSH / SFTP](https://help.mayfirst.org/en/guide/how-to-connect-to-your-website-host-with-ssh-or-sftp)

Pasteable Apache snippet: [`apache/kan.dsaneworleans.org.conf`](../apache/kan.dsaneworleans.org.conf).

## Outcomes to record (fill in as you go)

| Item | Value |
|------|--------|
| Hosting order / site id | |
| DNS record type (A / Alias) | |
| TLS ready (Let’s Encrypt) | |
| Postgres DB name | |
| Postgres user | |
| `POSTGRES_URL` stored in server `.env` only | yes / no |
| Loopback `PORT` | |
| App directory (absolute, no trailing slash) | e.g. `/home/sites/<SITE_ID>/files/kan` |
| Forever job item id (`red-item-<id>.service`) | |
| Node install notes (nvm path, version) | |

## 1. DNS

Under the **New Orleans DSA** May First hosting order (DNS tab):

1. Ensure `kan.dsaneworleans.org` exists as an **A** or **Alias** record pointing at May First as required by their UI.
2. Registrar NS should already point at May First (operator-controlled).
3. Wait until DNS resolves before enabling HTTPS-only web config if the panel rejects LE otherwise.

## 2. Web site

1. Hosting order → **Web Configuration** → add site for `kan.dsaneworleans.org`.
2. Prefer **HTTPS enabled** once DNS works; use HTTP-only temporarily if LE cannot issue yet, then switch.
3. Document Root: relative path under `web/` is fine (Kan will be reverse-proxied; Document Root need not hold the Node app). App files live under `files/` (next step).
4. Do **not** paste Apache ProxyPass until Node is listening on the chosen port (or expect 502s).

## 3. Postgres

1. Create a Postgres database and user in the control panel for Kan.
2. Build `POSTGRES_URL` and store it only in the server `.env` (never in git).
3. Note any quota limits for the hosting plan.

## 4. App layout on the site account

SSH in, then create a stable layout (names can match deploy scripts later):

```text
/home/sites/<SITE_ID>/files/kan/
  .env                 # secrets; mode 600
  start.sh             # forever entry (from release / ops scripts)
  current -> releases/<id>/
  releases/
```

Suggested:

```bash
mkdir -p "$HOME/files/kan/releases"
chmod 700 "$HOME/files/kan"
```

Record the absolute app directory **without a trailing slash** for the forever job.

## 5. Loopback port

1. Pick an unused high port on `127.0.0.1` for this site account.
2. Verify free: `ss -ltnp | grep 127.0.0.1:<PORT>` (or equivalent).
3. Put the same port in Apache `ProxyPass` and in the app listen config / env as required by the deploy layout.

## 6. Node (nvm)

Forever jobs are **non-login** shells — no interactive `~/.bashrc` PATH. Install Node via nvm under the site account if needed, and ensure `scripts/start.sh` exports a PATH that finds `node` (and any nvm shims) without relying on login profiles.

Document the Node major version that matches the pinned Kan release when known.

## 7. Apache reverse proxy

1. Copy [`apache/kan.dsaneworleans.org.conf`](../apache/kan.dsaneworleans.org.conf), replace `PORT`.
2. Paste into Web Configuration → Apache directives.
3. Save (panel restarts Apache). Wait ~15s.
4. Expect proxy errors until the forever job is up — that is OK at this stage.
5. No SPA `RewriteRule` → `index.html` (Kan is not a static SPA).

## 8. Forever scheduled job

Hosting order → **Scheduled Jobs** → add item:

| Field | Value |
|-------|--------|
| Schedule | **forever** |
| Command | `/bin/bash start.sh` (basename + bash — not `./start.sh` alone) |
| Directory | Absolute path to app root containing `start.sh`, **no trailing slash** |

Note the item id → unit name `red-item-<ITEM_ID>.service`.

```bash
systemctl --user status red-item-<ITEM_ID>.service
systemctl --user restart red-item-<ITEM_ID>.service
journalctl --user --unit red-item-<ITEM_ID>.service -n 50 --no-pager
```

Systemd must run Node in the **foreground** (no extra process manager / daemonize).

## 9. Bootstrap auth (after first successful deploy)

Follow [`docs/access-model.md`](./access-model.md): create admin → disable public signup → create invite link → share in members-only Discord → verify SMTP.

## 10. Health checks

- Public: `curl -I https://kan.dsaneworleans.org/`
- Local via SSH: `curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:<PORT>/`
- Confirm exact Kan health API path when wiring CI (upstream lists `/api/...` health endpoints).

## Rollback (ops)

Keep prior `releases/<id>/` directories; point `current` at a previous release and restart the forever job, or re-deploy an older GitHub Release asset.
