#!/usr/bin/env bash
#
# Stash 64 — self-bootstrapping AppImage builder.
#
# Run this from anywhere in the repo; it downloads Flutter and appimagetool
# into .stash64-sdk/ on first run (both git-ignored) and reuses them on
# subsequent runs. System Linux build deps (gtk3, clang, cmake, ninja,
# libsqlite3-dev) are installed via apt/pacman if missing — this step
# needs sudo.
#
# Usage:
#   scripts/build-appimage.sh         # builds for host arch (x86_64 or aarch64)
#   scripts/build-appimage.sh --clean # wipe toolchain and start fresh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SDK_DIR="$REPO_DIR/.stash64-sdk"
FLUTTER_DIR="$SDK_DIR/flutter"
TOOL_DIR="$SDK_DIR/appimage-tools"
DIST_DIR="$REPO_DIR/dist"

FLUTTER_VERSION="3.24.5"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)   APPIMAGE_ARCH="x86_64"  ;;
  aarch64)  APPIMAGE_ARCH="aarch64" ;;
  arm64)    APPIMAGE_ARCH="aarch64" ;;
  *) echo "unsupported arch: $ARCH" >&2; exit 2 ;;
esac
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${APPIMAGE_ARCH}.AppImage"

CLEAN=0
for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=1 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

if [ "$CLEAN" = "1" ]; then
  echo "==> Removing $SDK_DIR"
  rm -rf "$SDK_DIR"
fi

log()  { printf '\033[36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[33m!! %s\033[0m\n'  "$*" >&2; }
die()  { printf '\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# ── 0. Host sanity ────────────────────────────────────────────────────
command -v curl  >/dev/null || die "curl required"
command -v tar   >/dev/null || die "tar required"
command -v git   >/dev/null || die "git required"

# ── 1. System build deps ──────────────────────────────────────────────
have_pkg() {
  if command -v pkg-config >/dev/null 2>&1; then
    pkg-config --exists "$1" 2>/dev/null
  else
    return 1
  fi
}

install_apt_deps() {
  local pkgs=(clang cmake ninja-build pkg-config libgtk-3-dev libsqlite3-dev
              libstdc++-12-dev librsvg2-bin file xz-utils libfuse2)
  local missing=()
  for p in "${pkgs[@]}"; do
    dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed" \
      || missing+=("$p")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    log "Installing apt packages: ${missing[*]}"
    if [ "$(id -u)" = "0" ]; then
      apt-get update -y
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing[@]}"
    else
      sudo apt-get update -y
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing[@]}"
    fi
  fi
}

install_pacman_deps() {
  local pkgs=(clang cmake ninja pkgconf gtk3 sqlite librsvg fuse2)
  log "Installing pacman packages: ${pkgs[*]}"
  if [ "$(id -u)" = "0" ]; then
    pacman -Sy --needed --noconfirm "${pkgs[@]}"
  else
    sudo pacman -Sy --needed --noconfirm "${pkgs[@]}"
  fi
}

if command -v apt-get >/dev/null 2>&1; then
  install_apt_deps
elif command -v pacman >/dev/null 2>&1; then
  install_pacman_deps
else
  warn "Unknown package manager — install clang, cmake, ninja, gtk3-dev, sqlite3-dev, librsvg by hand"
fi

mkdir -p "$SDK_DIR" "$TOOL_DIR" "$DIST_DIR"

# ── 2. Flutter ────────────────────────────────────────────────────────
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  log "Downloading Flutter ${FLUTTER_VERSION}"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fSL --retry 4 --retry-delay 2 \
    -o "$tmp/flutter.tar.xz" "$FLUTTER_URL"
  log "Extracting Flutter"
  tar -xJf "$tmp/flutter.tar.xz" -C "$SDK_DIR"
  rm -rf "$tmp"
  trap - EXIT
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true
log "Flutter: $(flutter --version | head -n1)"

# ── 3. appimagetool ───────────────────────────────────────────────────
APPIMAGETOOL="$TOOL_DIR/appimagetool"
if [ ! -x "$APPIMAGETOOL" ]; then
  log "Downloading appimagetool for $APPIMAGE_ARCH"
  curl -fSL --retry 4 --retry-delay 2 \
    -o "$APPIMAGETOOL" "$APPIMAGETOOL_URL"
  chmod +x "$APPIMAGETOOL"
fi

# ── 4. Flutter build ──────────────────────────────────────────────────
cd "$REPO_DIR"
log "flutter config --enable-linux-desktop"
flutter config --enable-linux-desktop >/dev/null

log "flutter pub get"
flutter pub get

log "flutter build linux --release"
flutter build linux --release

BUNDLE_DIR="$(find "$REPO_DIR/build/linux" -type d -path '*/release/bundle' | head -1)"
[ -n "$BUNDLE_DIR" ] || die "Linux bundle not produced"

# ── 5. Assemble AppDir ────────────────────────────────────────────────
APP_NAME="Stash_64"
VERSION="$(grep -E '^version:' "$REPO_DIR/pubspec.yaml" | awk '{print $2}' | cut -d+ -f1)"
APPDIR="$REPO_DIR/build/${APP_NAME}.AppDir"
log "Assembling AppDir at $APPDIR"

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/applications"

cp -a "$BUNDLE_DIR"/. "$APPDIR/usr/bin/"

# Desktop file — prefer linux/stash64.desktop, fall back to appimage/ copy.
if [ -f "$REPO_DIR/linux/stash64.desktop" ]; then
  DESKTOP_SRC="$REPO_DIR/linux/stash64.desktop"
elif [ -f "$REPO_DIR/appimage/stash64.desktop" ]; then
  DESKTOP_SRC="$REPO_DIR/appimage/stash64.desktop"
else
  die "No stash64.desktop found under linux/ or appimage/"
fi
cp "$DESKTOP_SRC" "$APPDIR/stash64.desktop"
cp "$DESKTOP_SRC" "$APPDIR/usr/share/applications/stash64.desktop"

# Icon — convert SVG → 256x256 PNG via rsvg-convert.
if [ -f "$REPO_DIR/assets/icon/stash64_icon.svg" ]; then
  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w 256 -h 256 \
      "$REPO_DIR/assets/icon/stash64_icon.svg" -o "$APPDIR/stash64.png"
    cp "$APPDIR/stash64.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/stash64.png"
  elif command -v convert >/dev/null 2>&1; then
    convert -background none -resize 256x256 \
      "$REPO_DIR/assets/icon/stash64_icon.svg" "$APPDIR/stash64.png"
    cp "$APPDIR/stash64.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/stash64.png"
  else
    warn "No rsvg-convert or imagemagick; AppImage icon will be missing"
  fi
fi

cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/bash
SELF="$(readlink -f "$0")"
APPDIR="$(dirname "$SELF")"
export LD_LIBRARY_PATH="$APPDIR/usr/bin/lib:${LD_LIBRARY_PATH:-}"
export PATH="$APPDIR/usr/bin:$PATH"
exec "$APPDIR/usr/bin/stash_64" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# ── 6. Package ────────────────────────────────────────────────────────
OUTPUT="$DIST_DIR/${APP_NAME}-${VERSION}-${APPIMAGE_ARCH}.AppImage"
log "Packaging AppImage"

# FUSE isn't always available (containers, CI); --appimage-extract-and-run
# lets appimagetool execute even without FUSE.
if "$APPIMAGETOOL" --version >/dev/null 2>&1; then
  ARCH="$APPIMAGE_ARCH" "$APPIMAGETOOL" "$APPDIR" "$OUTPUT"
else
  ARCH="$APPIMAGE_ARCH" "$APPIMAGETOOL" --appimage-extract-and-run "$APPDIR" "$OUTPUT"
fi
chmod +x "$OUTPUT"

echo
printf '\033[32m════════════════════════════════════════════════════════\n'
printf '  AppImage ready\n'
printf '  %s\n' "$OUTPUT"
printf '  size: %s\n' "$(du -h "$OUTPUT" | cut -f1)"
printf '════════════════════════════════════════════════════════\033[0m\n\n'
