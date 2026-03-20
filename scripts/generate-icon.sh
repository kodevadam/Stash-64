#!/bin/bash
set -euo pipefail

# Generate PNG icons from the SVG source.
# Requires: inkscape or rsvg-convert (librsvg2-bin)
#
# Usage: ./scripts/generate-icon.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SVG="$PROJECT_DIR/assets/icon/stash64_icon.svg"

echo "=== Stash 64 Icon Generator ==="

if command -v rsvg-convert &>/dev/null; then
  echo "Using rsvg-convert..."
  rsvg-convert -w 256 -h 256 "$SVG" -o "$PROJECT_DIR/appimage/stash64.png"
  rsvg-convert -w 512 -h 512 "$SVG" -o "$PROJECT_DIR/assets/icon/stash64_512.png"
  rsvg-convert -w 1024 -h 1024 "$SVG" -o "$PROJECT_DIR/assets/icon/stash64_1024.png"
  echo "Done! Generated PNGs at 256, 512, and 1024px"
elif command -v inkscape &>/dev/null; then
  echo "Using inkscape..."
  inkscape "$SVG" -w 256 -h 256 -o "$PROJECT_DIR/appimage/stash64.png"
  inkscape "$SVG" -w 512 -h 512 -o "$PROJECT_DIR/assets/icon/stash64_512.png"
  inkscape "$SVG" -w 1024 -h 1024 -o "$PROJECT_DIR/assets/icon/stash64_1024.png"
  echo "Done! Generated PNGs at 256, 512, and 1024px"
elif command -v convert &>/dev/null; then
  echo "Using ImageMagick..."
  convert -background none -resize 256x256 "$SVG" "$PROJECT_DIR/appimage/stash64.png"
  convert -background none -resize 512x512 "$SVG" "$PROJECT_DIR/assets/icon/stash64_512.png"
  convert -background none -resize 1024x1024 "$SVG" "$PROJECT_DIR/assets/icon/stash64_1024.png"
  echo "Done! Generated PNGs at 256, 512, and 1024px"
else
  echo "ERROR: No SVG converter found."
  echo "Install one of: librsvg2-bin, inkscape, or imagemagick"
  echo "  sudo apt install librsvg2-bin"
  exit 1
fi
