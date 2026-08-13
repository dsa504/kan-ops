#!/usr/bin/env bash
# Run Drizzle migrations for the release pointed at by current/ (or KAN_CURRENT).
# Mirrors ghcr.io/kanbn/kan-migrate without Docker.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="${KAN_CURRENT:-$ROOT/current}"
ENV_FILE="${KAN_ENV_FILE:-$ROOT/.env}"
MIGRATE_DIR="${KAN_MIGRATE_DIR:-$APP/migrate}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "migrate.sh: missing env file: $ENV_FILE" >&2
  exit 1
fi
if [[ ! -f "$MIGRATE_DIR/drizzle.config.ts" ]]; then
  echo "migrate.sh: missing $MIGRATE_DIR/drizzle.config.ts" >&2
  exit 1
fi
if [[ ! -d "$MIGRATE_DIR/migrations" ]]; then
  echo "migrate.sh: missing $MIGRATE_DIR/migrations" >&2
  exit 1
fi

export PATH="/usr/sbin:/usr/bin:/sbin:/bin${PATH:+:$PATH}"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
fi
if [[ -n "${NODE_BIN:-}" ]]; then
  NODE="$NODE_BIN"
elif command -v node >/dev/null 2>&1; then
  NODE="$(command -v node)"
else
  echo "migrate.sh: node not found on PATH; install nvm Node or set NODE_BIN" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${POSTGRES_URL:-}" ]]; then
  echo "migrate.sh: POSTGRES_URL is empty" >&2
  exit 1
fi

# Upstream drizzle.config enables SSL when NODE_ENV=production.
# Override with KAN_MIGRATE_NODE_ENV=development if MF Postgres rejects SSL.
export NODE_ENV="${KAN_MIGRATE_NODE_ENV:-production}"

cd "$MIGRATE_DIR"
if [[ -x ./node_modules/.bin/drizzle-kit ]]; then
  exec ./node_modules/.bin/drizzle-kit migrate
fi
if [[ -f ./node_modules/drizzle-kit/bin.cjs ]]; then
  exec "$NODE" ./node_modules/drizzle-kit/bin.cjs migrate
fi

echo "migrate.sh: drizzle-kit not found under $MIGRATE_DIR/node_modules (re-pack release)" >&2
exit 1
