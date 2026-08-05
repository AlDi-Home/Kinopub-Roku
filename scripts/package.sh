#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$DIST_DIR/package-stage"
PACKAGE_NAME="${PACKAGE_NAME:-kinopub.zip}"
PACKAGE="$DIST_DIR/$PACKAGE_NAME"

"$ROOT_DIR/scripts/generate-config.sh"
"$ROOT_DIR/scripts/generate-build-info.sh"
mkdir -p "$DIST_DIR"
rm -f "$PACKAGE"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
trap 'rm -rf "$STAGE_DIR"' EXIT

cp -R "$ROOT_DIR/source" "$ROOT_DIR/components" "$ROOT_DIR/images" "$STAGE_DIR/"
cp "$ROOT_DIR/manifest" "$STAGE_DIR/manifest"

cd "$STAGE_DIR"
zip -r "$PACKAGE" manifest source components images -x "*.DS_Store"
echo "Created $PACKAGE"
