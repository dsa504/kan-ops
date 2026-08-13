#!/usr/bin/env bash
# Idempotent unpack → symlink current → migrate → restart forever unit.
# Intended to run ON the May First site account (CI will SSH and invoke it).
#
# Required env:
#   KAN_APP_ROOT   — absolute app root (e.g. /home/sites/SITE/files/kan), no trailing slash
#   SERVICE_NAME   — systemd user unit (e.g. red-item-12345.service)
#
# Usage:
#   KAN_APP_ROOT=... SERVICE_NAME=... ./remote-deploy.sh /path/to/kan-standalone-v0.6.0.tar.gz
set -euo pipefail

TARBALL="${1:?usage: remote-deploy.sh <tarball>}"
KAN_APP_ROOT="${KAN_APP_ROOT:?KAN_APP_ROOT is required}"
SERVICE_NAME="${SERVICE_NAME:?SERVICE_NAME is required}"
RELEASE_ID="${RELEASE_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
KEEP_RELEASES="${KEEP_RELEASES:-5}"

KAN_APP_ROOT="${KAN_APP_ROOT%/}"

if [[ ! -f "$TARBALL" ]]; then
  echo "remote-deploy: tarball not found: $TARBALL" >&2
  exit 1
fi

mkdir -p "$KAN_APP_ROOT/releases"
RELEASE_DIR="$KAN_APP_ROOT/releases/$RELEASE_ID"
if [[ -e "$RELEASE_DIR" ]]; then
  echo "remote-deploy: release dir already exists: $RELEASE_DIR" >&2
  exit 1
fi
mkdir -p "$RELEASE_DIR"

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

tar -xzf "$TARBALL" -C "$TMP"

shopt -s nullglob
entries=("$TMP"/*)
shopt -u nullglob
if [[ ${#entries[@]} -eq 1 && -d "${entries[0]}" ]]; then
  cp -a "${entries[0]}"/. "$RELEASE_DIR/"
else
  cp -a "$TMP"/. "$RELEASE_DIR/"
fi

if [[ ! -f "$RELEASE_DIR/bootstrap.cjs" ]]; then
  echo "remote-deploy: bootstrap.cjs missing after extract" >&2
  exit 1
fi

# Never overwrite server secrets
if [[ ! -f "$KAN_APP_ROOT/.env" ]]; then
  echo "remote-deploy: WARNING: $KAN_APP_ROOT/.env missing — create it before traffic" >&2
fi

install -m 755 "$RELEASE_DIR/start.sh" "$KAN_APP_ROOT/start.sh"
install -m 755 "$RELEASE_DIR/migrate.sh" "$KAN_APP_ROOT/migrate.sh"

ln -sfn "$RELEASE_DIR" "$KAN_APP_ROOT/current"

echo "remote-deploy: running migrations"
KAN_APP_ROOT="$KAN_APP_ROOT" "$KAN_APP_ROOT/migrate.sh"

echo "remote-deploy: restarting $SERVICE_NAME"
systemctl --user restart "$SERVICE_NAME"
systemctl --user --no-pager --full status "$SERVICE_NAME" || true

# Prune old releases (keep newest KEEP_RELEASES); never delete current target
if [[ "$KEEP_RELEASES" =~ ^[0-9]+$ ]] && [[ "$KEEP_RELEASES" -gt 0 ]]; then
  mapfile -t old < <(ls -1dt "$KAN_APP_ROOT/releases"/* 2>/dev/null | tail -n +"$((KEEP_RELEASES + 1))" || true)
  current_target="$(readlink -f "$KAN_APP_ROOT/current" || true)"
  for dir in "${old[@]:-}"; do
    [[ -z "$dir" ]] && continue
    if [[ "$(readlink -f "$dir")" == "$current_target" ]]; then
      continue
    fi
    echo "remote-deploy: pruning $dir"
    rm -rf "$dir"
  done
fi

echo "remote-deploy: OK release=$RELEASE_ID current -> $RELEASE_DIR"
