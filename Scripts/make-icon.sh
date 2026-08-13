#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICONSET_DIR="$ROOT_DIR/Packaging/AppIcon.iconset"
ICNS_PATH="$ROOT_DIR/Packaging/AppIcon.icns"
SWIFT_FILE="$ROOT_DIR/Packaging/make-icon.swift"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
swift "$SWIFT_FILE" "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"
echo "Created $ICNS_PATH"
