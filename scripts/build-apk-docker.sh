#!/usr/bin/env bash
#
# Stash 64 — APK builder that runs inside a pre-baked Flutter + Android SDK
# Docker image. Zero host setup beyond Docker itself: no JDK, no Flutter
# SDK, no Android SDK, no Gradle install needed.
#
# Usage:
#   scripts/build-apk-docker.sh           # release
#   scripts/build-apk-docker.sh --debug   # debug
#
# First run pulls ~1.3 GB of image layers; subsequent runs reuse them.
# Gradle's own cache is mapped into .stash64-sdk/gradle-cache/ so AGP and
# the androidx artifacts only download once across runs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$REPO_DIR/dist"
CACHE_DIR="$REPO_DIR/.stash64-sdk/gradle-cache"
PUB_DIR="$REPO_DIR/.stash64-sdk/pub-cache"

# ghcr.io/cirruslabs/flutter ships a multi-arch image per Flutter version
# with Flutter, Dart, the Android SDK (cmdline-tools, platforms, build-tools)
# and JDK 17 already installed. Pin the tag to the Flutter version our
# pubspec + CardThemeData usage requires.
IMAGE="ghcr.io/cirruslabs/flutter:3.27.3"

BUILD_MODE="release"
for arg in "$@"; do
  case "$arg" in
    --debug)   BUILD_MODE="debug" ;;
    --release) BUILD_MODE="release" ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

log()  { printf '\033[36m==> %s\033[0m\n' "$*"; }
die()  { printf '\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

command -v docker >/dev/null 2>&1 \
  || die "Docker not installed. Use scripts/build-apk.sh instead (downloads the SDKs into .stash64-sdk/)."

mkdir -p "$DIST_DIR" "$CACHE_DIR" "$PUB_DIR"

log "Pulling $IMAGE (first run only)"
docker pull "$IMAGE"

# Running as the invoking user avoids root-owned build/ artifacts. If
# SELinux is enforcing, the :z suffix on the bind mounts relabels.
UID_GID="$(id -u):$(id -g)"

log "Running flutter build apk --$BUILD_MODE inside $IMAGE"
docker run --rm \
  --user "$UID_GID" \
  -v "$REPO_DIR":/work \
  -v "$CACHE_DIR":/home/flutter/.gradle \
  -v "$PUB_DIR":/home/flutter/.pub-cache \
  -w /work \
  -e HOME=/home/flutter \
  -e PUB_CACHE=/home/flutter/.pub-cache \
  -e GRADLE_USER_HOME=/home/flutter/.gradle \
  "$IMAGE" \
  bash -c "flutter config --no-analytics >/dev/null && \
           flutter pub get && \
           flutter build apk --$BUILD_MODE"

APK_SRC="$REPO_DIR/build/app/outputs/flutter-apk/app-${BUILD_MODE}.apk"
[ -f "$APK_SRC" ] || die "Build finished but APK not found at $APK_SRC"

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
