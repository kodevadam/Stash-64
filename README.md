# Stash 64

A retro game collection browser built with Flutter. Designed as a touchscreen kiosk app for Raspberry Pi — walk up to your game den, browse your collection by console, genre, or number of players, see cover art and screenshots, and find exactly where each game is stored.

## Features

- **Browse by console** — N64, SNES, Genesis, NES, PlayStation, Game Boy, Dreamcast, Atari, and any custom consoles you add
- **Filter by genre, player count, storage location** — find that perfect 4-player game night pick
- **Cover art display** — add box art from files or search online to auto-download covers
- **Cover art search** — search RAWG and other APIs to find and download box art automatically
- **Screenshots** — attach and browse in-game screenshots with fullscreen swipe viewer
- **Storage locations** — track exactly where each game lives (Drawer 1, Shelf A, etc.)
- **Favorites** — star your top games and filter to favorites
- **Search** — instant search across your collection
- **Console management** — add, edit, and remove consoles with custom colors
- **Import/export** — full JSON backup and restore of your collection, including images (base64-encoded)
- **SummerCart64 flashcart upload** — for N64 games with an attached ROM, send the ROM to a connected SC64 via `sc64deployer` right from the game page. Live connect/lock status polling, spinner during transfer. Desktop only.
- **Per-game backdrops** — optional ambient images / GIFs / videos behind each game page. Blur + scrim sliders for readability; shuffle or cycle between multiple files. When nothing is attached, the cover art pans Ken-Burns-style behind the page.
- **Kiosk mode** — fullscreen toggle (F11 / double-tap), auto-hide cursor after 5s idle, attract mode screensaver after 5min idle
- **Touch + D-pad** — large tap targets (56dp), smooth scrolling, plus focus-ring D-pad navigation for Android TV / Chromecast with Google TV
- **Dark retro theme** — a warm dark UI with gold accents that fits the vibe

## Supported Platforms

| Platform | Status |
|----------|--------|
| Linux (x86_64) | Primary |
| Linux (ARM64/Raspberry Pi) | Primary |
| Windows | Supported |
| macOS | Supported |
| Android (phone/tablet) | Supported |
| Android TV / Chromecast with Google TV | Supported (sideload) |
| iOS | Supported |

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.2+)
- For Linux builds:
  ```bash
  sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libsqlite3-dev
  ```

### Run in development

```bash
flutter pub get
flutter run -d linux
```

### Build for Linux

```bash
flutter build linux --release
```

The binary will be at `build/linux/<arch>/release/bundle/stash_64`.

### Build for Android (phone / tablet / TV)

Three ways to get an APK — pick whichever matches your setup best:

**Docker (simplest, zero host setup):**
```bash
scripts/build-apk-docker.sh                 # release
scripts/build-apk-docker.sh --debug         # debug
```
Pulls `ghcr.io/cirruslabs/flutter:3.27.3` (~1.3 GB once, cached after)
and runs `flutter build apk` inside. Needs only Docker on the host.

**Self-bootstrapping native build:**
```bash
scripts/build-apk.sh                        # release
scripts/build-apk.sh --debug                # debug
scripts/build-apk.sh --clean                # wipe cached toolchain
```
Downloads Flutter + Android cmdline-tools into `.stash64-sdk/` on first
run. Host needs `curl`, `unzip`, `tar`, JDK 17+ (Android Gradle Plugin 8
won't run on older JDKs).

**Roll your own (Flutter + Android SDK already on PATH):**
```bash
flutter pub get
flutter build apk --release
```

Final APK lands at `dist/Stash_64-<version>-<mode>.apk` for the first two
options, or `build/app/outputs/flutter-apk/app-release.apk` for the
third.

The Android manifest declares touchscreen as **not required** and includes a
`LEANBACK_LAUNCHER` intent filter, so the same APK works on a Chromecast with
Google TV and shows up on the TV home row alongside other apps.

#### Sideloading to a Chromecast with Google TV

1. Enable **Developer options** → **USB debugging** (or **ADB debugging over
   network**) in the TV settings.
2. From your dev machine:
   ```bash
   adb connect <chromecast-ip>:5555
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```
3. Launch from **Apps → See all → Stash 64** (or the "From your phone" row
   depending on TV firmware).

#### Remote control navigation

The app responds to the Google TV remote out of the box:

- **D-pad** → move focus between game cards, filter chips, and toolbar buttons.
  The focused card shows a gold border and slight scale-up (focus ring only
  appears under directional navigation, so touch devices aren't affected).
- **Center / OK** → open the focused game.
- **Back** → standard Navigator pop.

### Build as AppImage

`scripts/build-appimage.sh` is self-bootstrapping — it downloads Flutter
and `appimagetool` into `.stash64-sdk/`, installs the Linux build deps
(`clang`, `cmake`, `ninja`, `gtk3`, `sqlite3-dev`, `librsvg`) via
apt/pacman, then builds.

```bash
scripts/build-appimage.sh
scripts/build-appimage.sh --clean   # wipe toolchain and start fresh
```

Output: `dist/Stash_64-<version>-<arch>.AppImage`. Runs on any modern Linux
distribution with GTK 3.

### Generate App Icon

```bash
# Requires librsvg2-bin, inkscape, or imagemagick
sudo apt install librsvg2-bin
./scripts/generate-icon.sh
```

Generates PNG icons at 256, 512, and 1024px from the SVG source at `assets/icon/stash64_icon.svg`.

### Raspberry Pi Kiosk Setup

1. Install Flutter on your Pi (or cross-compile on a desktop):
   ```bash
   # On Pi with 64-bit Raspberry Pi OS:
   sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libsqlite3-dev
   flutter build linux --release
   ```

2. For a kiosk setup, auto-start the app:
   ```bash
   # Add to ~/.config/autostart/stash64.desktop
   [Desktop Entry]
   Type=Application
   Name=Stash 64
   Exec=/path/to/stash_64
   ```

3. For a dedicated touchscreen kiosk, consider running in a minimal window manager like `openbox` to eliminate desktop chrome.

4. The app automatically enters attract mode (screensaver) after 5 minutes of inactivity. Touch or press any key to wake.

## Kiosk Mode Controls

| Action | Trigger |
|--------|---------|
| Toggle fullscreen | F11 or double-tap |
| Exit fullscreen | Escape |
| Dismiss attract mode | Touch anywhere or any key |
| Cursor auto-hides | After 5 seconds of inactivity |
| Attract mode activates | After 5 minutes of inactivity |

## Import & Export

From Settings, you can:
- **Export** your entire collection (consoles, games, cover art, screenshots) as a single JSON file with images base64-encoded
- **Import** from a previously exported JSON backup, adding new consoles and games without duplicating existing consoles

Backup files are saved to your documents directory as `stash64_backup_<timestamp>.json`.

Note: ROM files and backdrop videos are **not** included in the JSON backup —
the size would be prohibitive. Re-attach them on the target device after
restoring.

## SummerCart64 flashcart upload (N64)

Turn the N64 "Send to SummerCart64" button on under **Settings →
SummerCart64**. The feature is off by default.

What you need:
- A [SummerCart64](https://summercart64.dev) connected via USB.
- The [sc64deployer](https://github.com/Polprzewodnikowy/SummerCart64/releases)
  CLI on your PATH (or pick the binary manually from settings).
- On Linux, a udev rule so the FTDI USB device (`0403:6014`) is readable
  by your user without sudo — otherwise every upload requires root.

Workflow:
1. Edit a game on an N64 console and attach its ROM file. ROMs get copied
   into a ROM library directory (default `<appdocs>/roms/`, overridable
   from settings).
2. Open that game's detail page. A "SUMMERCART64" card appears with a
   live status line:
   - **Connected and ready** → Send button enabled.
   - **Locked by N64** → power off the N64 and the button un-greys in
     a couple of seconds.
   - **Not connected** / **sc64deployer not found** → button disabled.
3. Tap **Send to SC64**. Spinner spins for the second or two the flash
   takes, then a snackbar confirms success (or shows the sc64deployer
   error verbatim).

Android / Android TV: the button is hidden because sc64deployer is
desktop-only.

## Per-game backdrops

Turn **Settings → Game Page Backdrop** on. The feature is off by default.

- From the edit-game form, the **Backdrops** section lets you add any
  mix of images (`jpg/png/webp/bmp`), animated GIFs, and videos
  (`mp4/webm/mov/m4v/mkv`). Files are copied under
  `<appdocs>/backdrops/<game_id>/`.
- Multiple files per game play either **shuffle** (random pick per page
  visit) or **cycle** (crossfade through them in order). Videos loop.
- **Blur** (σ 0–40) and **Darken overlay** (0–100 %) sliders tune
  readability of text on top.
- If nothing is attached, the backdrop falls back to a slow Ken-Burns
  pan/zoom over the cover art — works day-one on every game, no extra
  files needed.

Performance tip: at 720p, 15 s muted H.264 clips run comfortably on Pi 4
and Chromecast with Google TV. Pi 3 wants 480p.

## Project Structure

```
lib/
├── main.dart                      # App entry point with kiosk wrapper
├── models/
│   ├── game.dart                  # Game data model
│   ├── game_console.dart          # Console data model
│   └── filter_state.dart          # Filter/sort state
├── data/
│   ├── database_helper.dart       # SQLite database layer
│   ├── sample_data.dart           # First-launch seed data
│   └── import_export_helper.dart  # JSON backup/restore
├── providers/
│   └── game_provider.dart         # State management (ChangeNotifier)
├── screens/
│   ├── home_screen.dart           # Main grid browser
│   ├── game_detail_screen.dart    # Game info + screenshots
│   ├── game_form_screen.dart      # Add/edit game form with cover search
│   ├── console_management_screen.dart  # Console CRUD with color picker
│   └── settings_screen.dart       # Settings, import/export, kiosk controls
├── widgets/
│   ├── game_card.dart             # Grid card with cover art
│   ├── filter_drawer.dart         # Filter/sort side drawer
│   ├── search_bar_widget.dart     # Touch-friendly search
│   ├── cover_art_search.dart      # Online cover art search dialog
│   └── kiosk_wrapper.dart         # Fullscreen, cursor hide, attract mode
└── theme/
    └── app_theme.dart             # Dark retro theme

scripts/
├── build-appimage.sh              # AppImage packager
└── generate-icon.sh               # SVG to PNG icon generator

appimage/
├── AppImageBuilder.yml            # AppImage recipe
└── stash64.desktop                # Desktop entry

assets/
├── covers/                        # Bundled cover art (gitkeep)
└── icon/
    └── stash64_icon.svg           # App icon source (controller + "64")
```

## Data Storage

- **Database**: SQLite via `sqflite_common_ffi` (works natively on Linux/ARM)
- **Images**: Cover art and screenshots are copied to the app's documents directory
- **Location**: `~/.local/share/stash_64/` on Linux

## License

MIT
