# Pre-built Stash 64 releases

Download the artifact you need, no build step required.

| File | Platform | Notes |
|---|---|---|
| `Stash_64-1.0.0-x86_64.AppImage` | Linux x86_64 (glibc ≥ 2.38 recommended) | Built against Ubuntu 24.04 / GTK 3. `chmod +x` and run. |
| _(APK coming soon — build locally with `scripts/build-apk.sh`)_ | Android 8+ / Android TV | See below. |

## Why no APK is checked in

The sandbox where these artifacts were produced has `dl.google.com`,
`maven.google.com`, every Android-SDK mirror I tried, and both major
OCI-registry blob CDNs (`pkg-containers.githubusercontent.com`,
`production.cloudflare.docker.com`) blocked at the network layer. There
is no way to pull the Android Gradle Plugin or the Android SDK from
inside that sandbox, so the APK has to be produced elsewhere.

Three one-command build paths for any normal internet connection:

```bash
# Option A — Docker (simplest; no JDK / Android SDK on host needed)
scripts/build-apk-docker.sh                 # release
scripts/build-apk-docker.sh --debug         # debug

# Option B — self-bootstrapping native build
scripts/build-apk.sh                        # release
scripts/build-apk.sh --debug                # debug
scripts/build-apk.sh --clean                # wipe cached toolchain

# Option C — drive Flutter yourself (if Flutter/Android SDK already set up)
flutter pub get && flutter build apk --release
```

- **Option A** pulls `ghcr.io/cirruslabs/flutter:3.27.3` (1.3 GB once, then
  cached) and runs `flutter build apk` inside. Nothing gets installed on
  the host.
- **Option B** downloads Flutter 3.24+ and the Android cmdline-tools into
  `.stash64-sdk/`, writes `android/local.properties`, accepts licenses,
  and builds. Host needs `curl`, `unzip`, `tar`, JDK 17+.

Final APK lands at `dist/Stash_64-<version>-<mode>.apk` either way.

## Rebuilding the AppImage yourself

```bash
scripts/build-appimage.sh
```

Same self-bootstrapping pattern. Needs `sudo` the first time so it can
install `clang`, `cmake`, `ninja`, `gtk3-dev`, `sqlite3-dev`, `librsvg`,
and `libfuse2[t64]` via `apt` or `pacman`.
