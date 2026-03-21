#!/bin/bash
set -euo pipefail

# Build Stash 64 as an AppImage
# Usage: ./scripts/build-appimage.sh [--arm64]
#
# Prerequisites:
#   - Flutter SDK installed and on PATH
#   - Linux build dependencies: sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libsqlite3-dev
#   - appimagetool: https://github.com/AppImage/appimagetool/releases

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APPDIR="$BUILD_DIR/AppDir"
ARCH="${1:-$(uname -m)}"

echo "=== Stash 64 AppImage Builder ==="
echo "Architecture: $ARCH"
echo ""

# Step 1: Build Flutter Linux release
echo "[1/4] Building Flutter Linux release..."
cd "$PROJECT_DIR"
flutter build linux --release

# Detect the build output path (x64 or arm64)
BUNDLE_DIR=$(find "$BUILD_DIR/linux" -path "*/release/bundle" -type d | head -1)
if [ -z "$BUNDLE_DIR" ]; then
  echo "ERROR: Could not find Flutter build output"
  exit 1
fi
echo "  Found bundle: $BUNDLE_DIR"

# Step 2: Prepare AppDir
echo "[2/4] Preparing AppDir..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/metainfo"

# Copy Flutter bundle
cp -r "$BUNDLE_DIR"/* "$APPDIR/usr/bin/"

# Copy desktop file
cp "$PROJECT_DIR/appimage/stash64.desktop" "$APPDIR/stash64.desktop"
cp "$PROJECT_DIR/appimage/stash64.desktop" "$APPDIR/usr/share/applications/"

# Convert SVG icon to PNG for AppImage compatibility
if [ -f "$PROJECT_DIR/assets/icon/stash64_icon.svg" ]; then
  if command -v rsvg-convert &>/dev/null; then
    echo "  Converting SVG icon to PNG..."
    rsvg-convert -w 256 -h 256 "$PROJECT_DIR/assets/icon/stash64_icon.svg" -o "$APPDIR/stash64.png"
    cp "$APPDIR/stash64.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/stash64.png"
  else
    echo "WARNING: rsvg-convert not found, cannot convert SVG icon to PNG"
    echo "  Install librsvg: sudo pacman -S librsvg (Arch) or sudo apt install librsvg2-bin (Debian)"
  fi
elif [ -f "$PROJECT_DIR/appimage/stash64.png" ]; then
  cp "$PROJECT_DIR/appimage/stash64.png" "$APPDIR/stash64.png"
  cp "$PROJECT_DIR/appimage/stash64.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
fi

# Create AppRun
cat > "$APPDIR/AppRun" << 'APPRUN'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export LD_LIBRARY_PATH="${HERE}/usr/bin/lib:${HERE}/usr/lib:${LD_LIBRARY_PATH:-}:/usr/lib:/usr/lib64:/usr/lib/x86_64-linux-gnu"
export GDK_BACKEND="${GDK_BACKEND:-x11}"
exec "${HERE}/usr/bin/stash_64" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# Step 3: Copy system libraries needed at runtime
echo "[3/4] Bundling runtime libraries..."
# SQLite is needed by sqflite_ffi
for lib in libsqlite3.so.0; do
  LIB_PATH=$(ldconfig -p | grep "$lib" | head -1 | awk '{print $NF}')
  if [ -n "$LIB_PATH" ]; then
    cp "$LIB_PATH" "$APPDIR/usr/lib/"
    echo "  Bundled: $lib"
  fi
done

# Step 4: Package as AppImage
echo "[4/4] Packaging AppImage..."
OUTPUT_NAME="Stash_64-${ARCH}.AppImage"

if command -v appimagetool &>/dev/null; then
  ARCH="$ARCH" appimagetool "$APPDIR" "$BUILD_DIR/$OUTPUT_NAME"
  echo ""
  echo "=== Done! ==="
  echo "AppImage: $BUILD_DIR/$OUTPUT_NAME"
else
  echo ""
  echo "WARNING: appimagetool not found. AppDir prepared at: $APPDIR"
  echo "Install appimagetool to package: https://github.com/AppImage/appimagetool/releases"
  echo "Then run: ARCH=$ARCH appimagetool $APPDIR $BUILD_DIR/$OUTPUT_NAME"
fi
