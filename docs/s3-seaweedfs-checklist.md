# May First checklist — SeaweedFS S3 (`s3.dsaneworleans.org`)

Interactive runbook mirroring Cooperative Codebase’s Seaweed setup (`s3.cooperativecodebase.com` in `cooperative-codebase/infrastructure`). For **New Orleans DSA** Kan uploads (avatars / attachments).

**Reference:** CC outcomes in `infrastructure/docs/KAN_MAY_FIRST_SETUP.md` (SeaweedFS / S3 section) + [`apache/s3.cooperativecodebase.com.conf`](https://forgejo.cooperativecodebase.com/cooperative-codebase/infrastructure/src/branch/main/apache/s3.cooperativecodebase.com.conf).

## For the implementing agent

1. Walk the human through MF steps; **wait for confirmation** before hosting-order / Apache / forever changes.
2. After each confirmed step, fill **Outcomes** below and commit to `dsa504/kan-ops` (ask before push if unclear).
3. Keep Apache snippet [`../apache/s3.dsaneworleans.org.conf`](../apache/s3.dsaneworleans.org.conf) in sync with what is pasted into MF.
4. Never commit S3 access keys / `.env` secrets.
5. **Port conflict:** CC Seaweed already uses **`127.0.0.1:8333`** on **weborigin015**. NOLA Kan uses **3055**. Pick a **free** S3 loopback port for this site (e.g. **8334** after `ss` check).

## Architecture

```
Apache (HTTPS) → ProxyPass → 127.0.0.1:<S3_PORT> → weed mini (forever job)
Objects under /home/sites/<SITE_ID>/files/seaweed/

Kan (site 388570) .env → S3_* + NEXT_PUBLIC_STORAGE_* → https://s3.dsaneworleans.org
```

## Outcomes (fill as you go)

| Item | Value |
|------|--------|
| Membership | New Orleans DSA |
| Hosting order domain / description | `s3.dsaneworleans.org` / SeaweedFS / Kan uploads |
| Web Configuration item / site id | **388641** (active) |
| Web origin host | `weborigin015.mayfirst.org` |
| SSH login | `ssh dsa-seaweed@shell.mayfirst.org` |
| SSH / SFTP username | `dsa-seaweed` (shell: `site388641writer@weborigin015`) |
| DNS aliases | **active** — `388637` (`s3…`), `388638` (`www.s3…`) → `c.webproxy.mayfirst.org` |
| TLS ready | **yes** — HTTPS enabled; MF “future home” OK (2026-08-14) |
| Disk quota (panel) | **5 GB** allocated / **~124 KB** used (web item) |
| App directory (no trailing slash) | `/home/sites/388641/files/seaweed` |
| Loopback S3 `PORT` | **8334** (`127.0.0.1`) — **8333**/8888/9333 taken by CC |
| Loopback master / filer / volume | **9334** / **8889** / **8081** |
| Forever job → `red-item-<id>.service` | **388643** → `red-item-388643.service` (**active**) |
| `weed` version / binary path | **4.41** (`de34a1a…`) / `$HOME/files/seaweed/bin/weed` |
| Buckets | `avatars`, `attachments` (**created**; UI upload OK 2026-08-14) |
| Apache config in this repo | `apache/s3.dsaneworleans.org.conf` (**pasted**) |
| Public S3 health | **yes** — GET `/` → **403**; HEAD → 405 via nginx (2026-08-14) |
| Kan `.env` S3 wired + restart | **yes** — `__ENV.js` + avatar/attachment upload OK (2026-08-14) |

### Done so far

- **2026-08-14:** Hosting order + DNS **388637**/**388638** + Web **388641** + HTTPS + `weed` **4.41** forever **388643** on **8334** (master **9334** / filer **8889** / volume **8081**).
- **2026-08-14:** Apache ProxyPass live for `https://s3.dsaneworleans.org`.
- **2026-08-14:** Kan `.env` S3 vars + restart; buckets exist; UI upload smoke OK.

## Walkthrough

### S0. New hosting order + DNS _(ask before creating)_

1. NOLA DSA membership → **Hosting Order** → Add.
2. Hostname: **`s3.dsaneworleans.org`** (description e.g. SeaweedFS / Kan uploads).
3. Note SSH username MF assigns (often something like `dsas3` / `s3` — record it).
4. Confirm DNS aliases auto-created (`s3…` + often `www.s3…` → `c.webproxy.mayfirst.org`).

**Update Outcomes** when done. Reply with hosting-order / DNS item ids + SSH username.

### S1. Web site + TLS

1. On the **S3** hosting order → Web Configuration → add site for `s3.dsaneworleans.org` (and `www` if offered).
2. HTTPS when DNS works; confirm placeholder + valid cert.
3. **Do not** paste ProxyPass yet.

### S2. SSH + layout

```bash
ssh <user>@shell.mayfirst.org
pwd   # /home/sites/<SITE_ID>
mkdir -p "$HOME/files/seaweed"/{bin,data}
chmod 700 "$HOME/files/seaweed"
```

### S3. Free loopback port

```bash
# On the S3 site SSH session (same weborigin as other tenants):
ss -ltn | grep -E '8333|8334|8343' || true
# Pick a free high port for weed S3 (default weed mini is 8333 — likely taken by CC).
```

Record **`S3_PORT`**.

### S4. Install `weed` + start script + credentials

Pin a current SeaweedFS Linux amd64 release (match CC if known; otherwise latest stable).

```bash
cd "$HOME/files/seaweed"
# Example — replace VERSION with a real release tag from GitHub seaweedfs/seaweedfs:
# curl -sL "https://github.com/seaweedfs/seaweedfs/releases/download/<VERSION>/linux_amd64.tar.gz" | tar -xz -C bin
# chmod 755 bin/weed
./bin/weed version
```

Generate keys (on your laptop or on the server; **store only in server files**, never git):

```bash
# example generators
openssl rand -hex 16   # access key
openssl rand -hex 32   # secret key
```

Create `s3.json` (mode `600`) under `$HOME/files/seaweed/`:

```json
{
  "identities": [
    {
      "name": "kan",
      "credentials": [{ "accessKey": "REPLACE_ACCESS", "secretKey": "REPLACE_SECRET" }],
      "actions": ["Admin", "Read", "Write", "List", "Tagging"]
    }
  ]
}
```

`start.sh` (foreground — forever requirement):

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
export PATH="$ROOT/bin:/usr/bin:/bin"
# Bind to loopback only; Apache terminates TLS.
# Ports offset from CC weed mini (8333/8888/9333/8080) on weborigin015.
exec weed mini \
  -dir="$ROOT/data" \
  -ip=127.0.0.1 \
  -ip.bind=127.0.0.1 \
  -master.port=9334 \
  -filer.port=8889 \
  -volume.port=8081 \
  -s3 \
  -s3.port=8334 \
  -s3.config="$ROOT/s3.json"
```

```bash
chmod 755 start.sh
# Quick foreground test before forever job:
# ./start.sh
# curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8334/
# expect e.g. 403 AccessDenied XML (S3 up), not connection refused
```

Create buckets (once S3 is up), e.g. with `aws` CLI from your laptop:

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=us-east-1
aws --endpoint-url https://s3.dsaneworleans.org s3 mb s3://avatars
aws --endpoint-url https://s3.dsaneworleans.org s3 mb s3://attachments
# Until Apache is live, use http://127.0.0.1:S3_PORT via SSH tunnel, or wait until S6.
```

### S5. Forever job _(ask before creating)_

| Field | Value |
|-------|--------|
| Schedule | forever |
| Command | `/bin/bash start.sh` |
| Directory | `/home/sites/<SITE_ID>/files/seaweed` (no trailing slash) |

```bash
systemctl --user status red-item-<ID>.service
journalctl --user --unit red-item-<ID>.service -n 50 --no-pager
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:S3_PORT/
```

### S6. Apache ProxyPass _(ask before pasting)_

Paste [`../apache/s3.dsaneworleans.org.conf`](../apache/s3.dsaneworleans.org.conf) (with correct `S3_PORT`). MF allowlist: **no** `AllowEncodedSlashes` / `ProxyTimeout`.

```bash
curl -sSI https://s3.dsaneworleans.org/ | head -20
# expect 403 XML AccessDenied + Amz request id style headers when auth required
```

### S7. Wire Kan `.env` + restart

On **Kan** site (`dsakan` / `/home/sites/388570/files/kan/.env`):

```bash
S3_REGION=us-east-1
S3_ENDPOINT=https://s3.dsaneworleans.org
S3_ACCESS_KEY_ID=...
S3_SECRET_ACCESS_KEY=...
S3_FORCE_PATH_STYLE=true
NEXT_PUBLIC_STORAGE_URL=https://s3.dsaneworleans.org
NEXT_PUBLIC_AVATAR_BUCKET_NAME=avatars
NEXT_PUBLIC_ATTACHMENTS_BUCKET_NAME=attachments
NEXT_PUBLIC_STORAGE_DOMAIN=s3.dsaneworleans.org
```

```bash
systemctl --user restart red-item-388573.service
curl -sS https://kan.dsaneworleans.org/__ENV.js
# should include STORAGE_* public vars
```

Smoke: upload an avatar or card attachment in Kan.

## Related

| Doc | Why |
|-----|-----|
| [`may-first-checklist.md`](./may-first-checklist.md) | NOLA Kan site (388570) |
| [`.env.example`](../.env.example) | Kan env names |
| CC `KAN_MAY_FIRST_SETUP.md` | Proven Seaweed on MF shared hosting |
