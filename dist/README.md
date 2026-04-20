# Pre-built Stash 64 releases

Download the artifact you need, no build step required.

| File | Platform | Notes |
|---|---|---|
| `Stash_64-1.0.0-x86_64.AppImage` | Linux x86_64 (glibc ≥ 2.38 recommended) | Built against Ubuntu 24.04 / GTK 3. `chmod +x` and run. |
| _(APK coming soon — build locally with `scripts/build-apk.sh`)_ | Android 8+ / Android TV | See below. |

## Why no APK is checked in

The sandbox where these artifacts were produced has `dl.google.com` and
`maven.google.com` blocked at the network layer, which makes it
impossible to download the Android command-line tools or resolve the
Android Gradle Plugin in that environment. From any machine with normal
internet access:

```bash
scripts/build-apk.sh                # release
scripts/build-apk.sh --debug        # debug
```

…downloads Flutter + the Android SDK into `.stash64-sdk/`, writes
`android/local.properties`, accepts licenses, and drops the signed APK
at `dist/Stash_64-<version>-<mode>.apk`.

Host requirements: `curl`, `unzip`, `tar`, JDK 17+ (the repo was tested
with JDK 21).

## Rebuilding the AppImage yourself

```bash
scripts/build-appimage.sh
```

Same self-bootstrapping pattern. Needs `sudo` the first time so it can
install `clang`, `cmake`, `ninja`, `gtk3-dev`, `sqlite3-dev`, `librsvg`,
and `libfuse2[t64]` via `apt` or `pacman`.
