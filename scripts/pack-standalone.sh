#!/usr/bin/env bash
# Assemble kan-standalone-<version>.tar.gz from a built Kan checkout.
#
# Prerequisites (CI or local spike):
#   - Kan cloned at KAN_SRC, checked out to the pin in KAN_VERSION
#   - Built with NEXT_PUBLIC_USE_STANDALONE_OUTPUT=true
#     e.g. pnpm install && pnpm build --filter=@kan/web
#
# Usage:
#   ./scripts/pack-standalone.sh
#   KAN_SRC=/path/to/kan VERSION=v0.6.0 ./scripts/pack-standalone.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KAN_SRC="${KAN_SRC:-$REPO_ROOT/upstream/kan}"
VERSION="${VERSION:-$(tr -d '[:space:]' <"$REPO_ROOT/KAN_VERSION")}"
OUT_DIR="${OUT_DIR:-$REPO_ROOT/dist}"
STAGE="${STAGE:-$OUT_DIR/stage-kan-standalone-$VERSION}"
TARBALL="$OUT_DIR/kan-standalone-${VERSION}.tar.gz"

WEB="$KAN_SRC/apps/web"
STANDALONE="$WEB/.next/standalone"
STATIC="$WEB/.next/static"
PUBLIC_DIR="$WEB/public"
BOOTSTRAP="$WEB/bootstrap.cjs"
DB_PKG="$KAN_SRC/packages/db"

need_file() {
  if [[ ! -e "$1" ]]; then
    echo "pack-standalone: missing $1" >&2
    exit 1
  fi
}

need_file "$STANDALONE"
need_file "$STATIC"
need_file "$PUBLIC_DIR"
need_file "$BOOTSTRAP"
need_file "$DB_PKG/drizzle.config.ts"
need_file "$DB_PKG/migrations"
need_file "$REPO_ROOT/scripts/start.sh"
need_file "$REPO_ROOT/scripts/migrate.sh"

rm -rf "$STAGE"
mkdir -p "$STAGE" "$OUT_DIR"

# Match apps/web/Dockerfile web stage layout
cp -a "$STANDALONE"/. "$STAGE/"
mkdir -p "$STAGE/apps/web/.next" "$STAGE/apps/web/public"
cp -a "$STATIC" "$STAGE/apps/web/.next/static"
cp -a "$PUBLIC_DIR"/. "$STAGE/apps/web/public/"
cp "$BOOTSTRAP" "$STAGE/bootstrap.cjs"

# Migrate bundle (kan-migrate image purpose, without Docker)
mkdir -p "$STAGE/migrate/migrations"
cp "$DB_PKG/drizzle.config.ts" "$STAGE/migrate/drizzle.config.ts"
cp -a "$DB_PKG/migrations"/. "$STAGE/migrate/migrations/"
cat >"$STAGE/migrate/package.json" <<'EOF'
{
  "name": "kan-migrate-bundle",
  "private": true,
  "description": "Offline drizzle-kit migrate deps for May First deploys"
}
EOF

echo "pack-standalone: npm install migrate deps in CI staging dir"
(
  cd "$STAGE/migrate"
  npm install drizzle-kit@0.28.1 drizzle-orm@0.42.0 pg --save-exact --omit=dev
)

cp "$REPO_ROOT/scripts/start.sh" "$STAGE/start.sh"
cp "$REPO_ROOT/scripts/migrate.sh" "$STAGE/migrate.sh"
chmod 755 "$STAGE/start.sh" "$STAGE/migrate.sh"
printf '%s\n' "$VERSION" >"$STAGE/VERSION"

# Top-level directory inside the archive for stable extract
BUNDLE_NAME="kan-standalone-${VERSION}"
BUNDLE_PARENT="$OUT_DIR/bundle-$$"
mkdir -p "$BUNDLE_PARENT"
mv "$STAGE" "$BUNDLE_PARENT/$BUNDLE_NAME"

tar -czf "$TARBALL" -C "$BUNDLE_PARENT" "$BUNDLE_NAME"
rm -rf "$BUNDLE_PARENT"

echo "pack-standalone: wrote $TARBALL"
tar -tzf "$TARBALL" | head -n 40
echo "..."
# Sanity: entrypoints present
tar -tzf "$TARBALL" | grep -E "/bootstrap\.cjs$|/start\.sh$|/migrate/drizzle\.config\.ts$" >/dev/null
echo "pack-standalone: entrypoints OK"
