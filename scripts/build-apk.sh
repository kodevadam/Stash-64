#!/usr/bin/env bash
#
# Stash 64 — self-bootstrapping Android APK builder.
#
# Run this from anywhere in the repo; it downloads Flutter and the Android
# command-line tools into .stash64-sdk/ on first run (both git-ignored) and
# reuses them on subsequent runs. The resulting release APK is copied to
# dist/Stash_64-<version>.apk.
#
# Usage:
#   scripts/build-apk.sh              # release build
#   scripts/build-apk.sh --debug      # debug build (unsigned)
#   scripts/build-apk.sh --clean      # wipe SDKs and start fresh
#
# Designed to work on Debian/Ubuntu and Arch-family Linux.  Only unzip,
# curl/wget, and a JDK 17 are required on the host — everything else is
# downloaded into the repo-local toolchain directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SDK_DIR="$REPO_DIR/.stash64-sdk"
FLUTTER_DIR="$SDK_DIR/flutter"
ANDROID_DIR="$SDK_DIR/android-sdk"
DIST_DIR="$REPO_DIR/dist"

# Pin toolchain versions so builds are reproducible.
FLUTTER_VERSION="3.24.5"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
ANDROID_PLATFORM="android-34"
ANDROID_BUILD_TOOLS="34.0.0"

BUILD_MODE="release"
CLEAN=0
for arg in "$@"; do
  case "$arg" in
    --debug)   BUILD_MODE="debug" ;;
    --release) BUILD_MODE="release" ;;
    --clean)   CLEAN=1 ;;
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

# ── 0. Sanity check host tools ────────────────────────────────────────
need_host() {
  command -v "$1" >/dev/null 2>&1 \
    || die "Need '$1' on PATH. Install it first (apt: $2 / pacman: $3)."
}
need_host curl     curl      curl
need_host unzip    unzip     unzip
need_host tar      tar       tar
need_host java     openjdk-17-jdk  jdk17-openjdk

JAVA_MAJOR="$(java -version 2>&1 | awk -F'[".]' '/version/{print $2; exit}')"
if [ -z "$JAVA_MAJOR" ] || [ "$JAVA_MAJOR" -lt 17 ]; then
  die "Java 17+ required (found: ${JAVA_MAJOR:-unknown}). AGP 8 won't run on older JDKs."
fi

mkdir -p "$SDK_DIR" "$DIST_DIR"

# ── 1. Flutter ────────────────────────────────────────────────────────
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

# Flutter's git self-update check fails if the bundled repo dir isn't a
# valid git checkout; disable it, we pin the version ourselves.
git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true

log "Flutter: $(flutter --version | head -n1)"

# ── 2. Android SDK ────────────────────────────────────────────────────
if [ ! -x "$ANDROID_DIR/cmdline-tools/latest/bin/sdkmanager" ]; then
  log "Downloading Android cmdline-tools"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fSL --retry 4 --retry-delay 2 \
    -o "$tmp/tools.zip" "$CMDLINE_TOOLS_URL"
  mkdir -p "$ANDROID_DIR/cmdline-tools"
  unzip -q "$tmp/tools.zip" -d "$tmp/extracted"
  # Google ships the tools under cmdline-tools/ — sdkmanager insists on
  # being at cmdline-tools/latest/ so it can install updates side-by-side.
  mv "$tmp/extracted/cmdline-tools" "$ANDROID_DIR/cmdline-tools/latest"
  rm -rf "$tmp"
  trap - EXIT
fi

export ANDROID_HOME="$ANDROID_DIR"
export ANDROID_SDK_ROOT="$ANDROID_DIR"
export PATH="$ANDROID_DIR/cmdline-tools/latest/bin:$ANDROID_DIR/platform-tools:$PATH"

# Install platform + build-tools if not already present.
need_pkg() {
  local pkg="$1" dir="$2"
  if [ ! -d "$ANDROID_DIR/$dir" ]; then
    log "Installing $pkg"
    yes | sdkmanager --sdk_root="$ANDROID_DIR" --install "$pkg" >/dev/null
  fi
}
need_pkg "platform-tools"                     "platform-tools"
need_pkg "platforms;$ANDROID_PLATFORM"        "platforms/$ANDROID_PLATFORM"
need_pkg "build-tools;$ANDROID_BUILD_TOOLS"   "build-tools/$ANDROID_BUILD_TOOLS"

log "Accepting Android SDK licenses"
yes | sdkmanager --sdk_root="$ANDROID_DIR" --licenses >/dev/null 2>&1 || true
yes | flutter doctor --android-licenses >/dev/null 2>&1 || true

# ── 3. Wire Flutter to the local Android SDK ──────────────────────────
cat > "$REPO_DIR/android/local.properties" <<EOF
sdk.dir=$ANDROID_DIR
flutter.sdk=$FLUTTER_DIR
flutter.buildMode=$BUILD_MODE
flutter.versionName=$(grep -E '^version:' "$REPO_DIR/pubspec.yaml" | awk '{print $2}' | cut -d+ -f1)
flutter.versionCode=$(grep -E '^version:' "$REPO_DIR/pubspec.yaml" | awk '{print $2}' | cut -d+ -f2)
EOF

# ── 4. Build ──────────────────────────────────────────────────────────
cd "$REPO_DIR"
log "flutter pub get"
flutter pub get

log "flutter build apk --$BUILD_MODE"
flutter build apk "--$BUILD_MODE"

APK_SRC="$REPO_DIR/build/app/outputs/flutter-apk/app-${BUILD_MODE}.apk"
if [ ! -f "$APK_SRC" ]; then
  die "Build finished but APK not found at $APK_SRC"
fi

VERSION="$(grep -E '^version:' "$REPO_DIR/pubspec.yaml" | awk '{print $2}')"
APK_OUT="$DIST_DIR/Stash_64-${VERSION}-${BUILD_MODE}.apk"
cp "$APK_SRC" "$APK_OUT"

echo
printf '\033[32m════════════════════════════════════════════════════════\n'
printf '  APK ready\n'
printf '  %s\n' "$APK_OUT"
printf '  size: %s\n' "$(du -h "$APK_OUT" | cut -f1)"
printf '════════════════════════════════════════════════════════\033[0m\n\n'
printf 'Sideload with:\n'
printf '  adb install -r "%s"\n\n' "$APK_OUT"
