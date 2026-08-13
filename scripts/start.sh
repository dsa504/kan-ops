#!/usr/bin/env bash
# Forever-job entrypoint for Kan on May First.
# Directory in the control panel must be this script's parent (KAN_APP_ROOT),
# with no trailing slash. Command: /bin/bash start.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="${KAN_CURRENT:-$ROOT/current}"
ENV_FILE="${KAN_ENV_FILE:-$ROOT/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "start.sh: missing env file: $ENV_FILE" >&2
  exit 1
fi
if [[ ! -f "$APP/bootstrap.cjs" ]]; then
  echo "start.sh: missing $APP/bootstrap.cjs (deploy a release / fix current symlink)" >&2
  exit 1
fi

# Non-login forever shells have a minimal PATH — prefer nvm if present.
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
  echo "start.sh: node not found on PATH; install nvm Node or set NODE_BIN" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

export NODE_ENV="${NODE_ENV:-production}"
# Bind loopback for Apache ProxyPass (override in .env if needed).
export HOSTNAME="${HOSTNAME:-127.0.0.1}"
export PORT="${PORT:?PORT must be set in .env (loopback port Apache proxies to)}"

cd "$APP"
# Foreground required — systemd/forever is the process manager.
exec "$NODE" bootstrap.cjs
