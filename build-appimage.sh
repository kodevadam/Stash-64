#!/bin/bash
set -euo pipefail

# ── Stash 64 AppImage Builder ──────────────────────────────────────────
# For CachyOS / Arch Linux. Requires: flutter, gtk3, cmake, ninja, clang
#
# Usage:
#   ./build-appimage.sh
#
# Prerequisites (CachyOS/Arch):
#   sudo pacman -S flutter gtk3 cmake ninja clang pkgconf base-devel
#   (or install flutter via AUR / manual if not in repos)
# ────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Stash_64"
APP_ID="com.stash64.app"
VERSION="1.0.0"

# ── 1. Check dependencies ──────────────────────────────────────────────
echo "==> Checking dependencies..."
for cmd in flutter cmake ninja pkg-config; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' not found. Install it first."
    echo "  sudo pacman -S flutter gtk3 cmake ninja clang pkgconf"
    exit 1
  fi
done

if ! pkg-config --exists gtk+-3.0; then
  echo "ERROR: gtk+-3.0 not found. Install gtk3:"
  echo "  sudo pacman -S gtk3"
  exit 1
fi

# ── 2. Build Flutter Linux release ─────────────────────────────────────
echo "==> Getting Flutter dependencies..."
flutter pub get

echo "==> Building Linux release..."
flutter build linux --release

BUNDLE_DIR="build/linux/x64/release/bundle"

if [ ! -f "$BUNDLE_DIR/stash_64" ]; then
  echo "ERROR: Build failed — binary not found at $BUNDLE_DIR/stash_64"
  exit 1
fi

echo "==> Build successful: $BUNDLE_DIR/stash_64"

# ── 3. Download appimagetool if needed ─────────────────────────────────
TOOL_DIR="$SCRIPT_DIR/.appimage-tools"
APPIMAGETOOL="$TOOL_DIR/appimagetool"

if [ ! -x "$APPIMAGETOOL" ]; then
  echo "==> Downloading appimagetool..."
  mkdir -p "$TOOL_DIR"
  curl -fSL -o "$APPIMAGETOOL" \
    "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
  chmod +x "$APPIMAGETOOL"
fi

# ── 4. Assemble AppDir ─────────────────────────────────────────────────
APPDIR="$SCRIPT_DIR/build/${APP_NAME}.AppDir"
echo "==> Assembling AppDir at $APPDIR..."

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/icons/hicolor/scalable/apps"
mkdir -p "$APPDIR/usr/share/applications"

# Copy the entire Flutter bundle
cp -a "$BUNDLE_DIR"/. "$APPDIR/usr/bin/"

# Desktop file
cp linux/stash64.desktop "$APPDIR/stash64.desktop"
cp linux/stash64.desktop "$APPDIR/usr/share/applications/stash64.desktop"

# Icon — use the SVG, also create a symlink at AppDir root
if [ -f "assets/icon/stash64_icon.svg" ]; then
  cp "assets/icon/stash64_icon.svg" "$APPDIR/usr/share/icons/hicolor/scalable/apps/stash64.svg"
  cp "assets/icon/stash64_icon.svg" "$APPDIR/stash64.svg"
else
  # Fallback: generate a simple placeholder icon
  echo "WARNING: No icon found, creating placeholder"
  convert -size 256x256 xc:'#1a1a2e' -fill '#FFD700' -gravity center \
    -pointsize 48 -annotate +0+0 'S64' "$APPDIR/stash64.png" 2>/dev/null || true
fi

# AppRun launcher script
cat > "$APPDIR/AppRun" << 'APPRUN'
#!/bin/bash
SELF="$(readlink -f "$0")"
APPDIR="$(dirname "$SELF")"
export LD_LIBRARY_PATH="$APPDIR/usr/bin/lib:$APPDIR/usr/lib:${LD_LIBRARY_PATH:-}"
export PATH="$APPDIR/usr/bin:$PATH"
exec "$APPDIR/usr/bin/stash_64" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# ── 5. Build AppImage ──────────────────────────────────────────────────
OUTPUT="$SCRIPT_DIR/build/${APP_NAME}-${VERSION}-x86_64.AppImage"
echo "==> Building AppImage..."

# appimagetool needs FUSE; if unavailable, use --appimage-extract-and-run
if "$APPIMAGETOOL" --version &>/dev/null; then
  ARCH=x86_64 "$APPIMAGETOOL" "$APPDIR" "$OUTPUT"
else
  ARCH=x86_64 "$APPIMAGETOOL" --appimage-extract-and-run "$APPDIR" "$OUTPUT"
fi

chmod +x "$OUTPUT"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  AppImage built successfully!"
echo "  $OUTPUT"
echo "  Size: $(du -h "$OUTPUT" | cut -f1)"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Run it with:"
echo "  ./build/${APP_NAME}-${VERSION}-x86_64.AppImage"
