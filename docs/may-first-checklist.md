# May First checklist — Kan (`kan.dsaneworleans.org`)

Human steps in the May First members control panel and on the site SSH account. Do **not** apply production-adjacent changes without confirmation from the operator.

Control panel: https://members.mayfirst.org/cp/

## Hosting model (important)

May First allows **one web site per hosting order**. Kan must **not** share the chapter’s existing site hosting order.

Create a **new hosting order** under the **New Orleans DSA** May First **membership**, dedicated to Kan (`kan.dsaneworleans.org`). That order gets its own SSH user, `files/` / `web/` tree, Scheduled Jobs, Postgres items, and Web Configuration.

Do **not** try to add a second Web Configuration item on an order that already has a site.

Official guides:

- [Create a new hosting order (new web site)](https://help.mayfirst.org/en/guide/how-to-create-a-new-website-in-the-control-panel)
- [How to add a web site](https://help.mayfirst.org/en/guide/how-to-add-web-site) (after the order exists)
- [DNS records](https://help.mayfirst.org/en/guide/how-to-create-web-dns-record)
- [systemd / forever web service](https://help.mayfirst.org/en/guide/how-to-use-a-systemd-service-to-run-web-app)
- [SSH / SFTP](https://help.mayfirst.org/en/guide/how-to-connect-to-your-website-host-with-ssh-or-sftp)

Pasteable Apache snippet: [`apache/kan.dsaneworleans.org.conf`](../apache/kan.dsaneworleans.org.conf).

## Outcomes to record (fill in as you go)

| Item | Value |
|------|--------|
| Membership | New Orleans DSA (existing) |
| **New** hosting order name / id | |
| Web Configuration item / site id | **388570** (`/home/sites/388570/…`) |
| Web origin host | `weborigin015.mayfirst.org` |
| SSH login | `ssh dsakan@shell.mayfirst.org` (MF shell hop; session lands as `site388570writer@weborigin015`) |
| SSH / SFTP username for this order | `dsakan` |
| DNS (auto-created with order) | Alias `kan.dsaneworleans.org` → `c.webproxy.mayfirst.org` (item **388566**); Alias `www.kan.dsaneworleans.org` → `c.webproxy.mayfirst.org` (item **388567**); both active 2026-08-13 |
| TLS ready (Let’s Encrypt) | **yes** — https enabled; browser reports valid cert; MF “future home” page OK (2026-08-13) |
| Postgres item id | **388571** |
| Postgres host | `psql002.mayfirst.org` (URL host in panel: `psql002.mayfirst.cx`) |
| Postgres DB name | `dsakan_kan` (MF ties DB name to the DB user; no separate choice) |
| Postgres user | `dsakan_kan` |
| Postgres max connections / quota | 25 / 1gb |
| `POSTGRES_URL` shape (password only on server) | `postgresql://dsakan_kan:…@psql002.mayfirst.cx/dsakan_kan` |
| `POSTGRES_URL` stored in server `.env` only | pending (create in §4 / first deploy) |
| Loopback `PORT` | **3055** (`127.0.0.1`; verified free with `ss`) |
| App directory (absolute, no trailing slash) | `/home/sites/388570/files/kan` (created; `releases/` present) |
| Forever job item id (`red-item-<id>.service`) | **388573** → `red-item-388573.service` (Directory `/home/sites/388570/files/kan`, Command `/bin/bash start.sh`) |
| Node install notes | System **`/usr/bin/node` v20.19.2** (meets Kan `>=20.18.1` / `.nvmrc` 20.18); nvm not required on this account |

## 0. New hosting order

1. In the control panel, open the **New Orleans DSA** membership (breadcrumb member name — not an existing site’s hosting order).
2. **Hosting Order** service → **Add a new item**.
3. When prompted for the site hostname / subdomain, use `kan.dsaneworleans.org` (under the chapter domain already on May First DNS).
4. Completing the order **creates the DNS Alias records for you** — you usually do **not** add them by hand. MF also creates a `www.` alias for the same name.
5. Set or reset the new order’s login password as MF instructs (credentials stay out of git). SSH user for this order: **`dsakan`**.
6. Switch the control panel context to **this new hosting order** for all later steps (DNS verify, Web Configuration, Postgres, Scheduled Jobs, SSH).

## 1. DNS (verify)

On the **Kan hosting order** → **DNS** tab, confirm the auto-created aliases are **active**. For this deploy:

| Item id | Type | Name | Target |
|--------:|------|------|--------|
| 388566 | alias | `kan.dsaneworleans.org` | `c.webproxy.mayfirst.org` |
| 388567 | alias | `www.kan.dsaneworleans.org` | `c.webproxy.mayfirst.org` |

1. Registrar NS for `dsaneworleans.org` should already point at May First (operator-controlled).
2. Optionally check public resolution: `dig +short kan.dsaneworleans.org CNAME` (expect the webproxy name or its chain).
3. Wait until DNS resolves before enabling HTTPS-only web config if the panel rejects Let’s Encrypt otherwise.

## 2. Web site

Still on the **Kan hosting order**:

1. **Web Configuration** → **Add a new item**. Include **`kan.dsaneworleans.org`** (and optionally **`www.kan.dsaneworleans.org`** if the form allows multiple names — both aliases already exist).
2. Prefer **HTTPS enabled** once DNS works; use HTTP-only temporarily if LE cannot issue yet, then switch.
3. Document Root: relative path under `web/` is fine (Kan will be reverse-proxied; Document Root need not hold the Node app). App files live under `files/` (next step).
4. Do **not** paste Apache ProxyPass until Node is listening on the chosen port (or expect 502s).

**Done for this deploy:** item **388570** on `weborigin015.mayfirst.org`, domain `kan.dsaneworleans.org`, encryption **https enabled**, placeholder “future home” page confirmed in browser with a valid cert.

## 3. Postgres

1. Create a Postgres database and user **on the Kan hosting order** (not the main site order).
2. On May First, the **database name and DB username are the same** (no separate DB name field). For Kan we used **`dsakan_kan`**.
3. Build `POSTGRES_URL` from the panel connection string and store it only in the server `.env` (never in git). Prefer the `postgresql://` scheme Kan expects if the panel shows `psql://`.
4. Note host, max connections, and disk quota.

**Done for this deploy:** item **388571** on `psql002.mayfirst.org`, user/db **`dsakan_kan`**, panel URL host `psql002.mayfirst.cx`, max connections 25, quota 1gb.

## 4. App layout on the site account

SSH via May First’s shell host (not the web origin hostname directly):

```bash
ssh dsakan@shell.mayfirst.org
```

After login you typically see a site writer prompt on the web origin, e.g. `site388570writer@weborigin015`, with home `/home/sites/388570`.

Create a stable layout (names match deploy scripts):

```text
/home/sites/388570/files/kan/
  .env                 # secrets; mode 600
  start.sh             # forever entry (from release / ops scripts)
  current -> releases/<id>/
  releases/
```

```bash
mkdir -p "$HOME/files/kan/releases"
chmod 700 "$HOME/files/kan"
pwd                    # /home/sites/388570
ls -la "$HOME/files/kan"
```

Forever **Directory** (absolute, **no trailing slash**): `/home/sites/388570/files/kan`.

**Done for this deploy:** app dir created; `releases/` present under `files/kan`.

## 5. Loopback port

1. Pick an unused high port on `127.0.0.1` for this site account.
2. Verify free: `ss -ltnp | grep 127.0.0.1:<PORT>` (or equivalent).
3. Put the same port in Apache `ProxyPass` and in the app `.env` (`PORT=`).

**Done for this deploy:** **`PORT=3055`** looks free on the Kan site account.

## 6. Node

Forever jobs are **non-login** shells — no interactive `~/.bashrc` PATH. `scripts/start.sh` puts `/usr/bin` on `PATH` and sources nvm only if `$HOME/.nvm` exists.

Check what the site account already has:

```bash
command -v node; node -v
```

Kan `v0.6.0` wants Node `>=20.18.1` (upstream `.nvmrc`: `20.18`). If the account already has a suitable `/usr/bin/node`, **skip nvm**.

**Done for this deploy:** `/usr/bin/node` **v20.19.2** — no nvm install needed.

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
