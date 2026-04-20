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
- **Kiosk mode** — fullscreen toggle (F11 / double-tap), auto-hide cursor after 5s idle, attract mode screensaver after 5min idle
- **Touch-optimized** — large tap targets (56dp), smooth scrolling, designed for touchscreen kiosks
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

```bash
flutter pub get
flutter build apk --release
```

APK lands at `build/app/outputs/flutter-apk/app-release.apk`.

For a debug build you can sideload without signing setup:

```bash
flutter build apk --debug
# or, if the device is already adb-connected:
flutter install
```

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

```bash
# Install appimagetool first:
# https://github.com/AppImage/appimagetool/releases

./scripts/build-appimage.sh
```

This produces a portable `Stash_64-<arch>.AppImage` that runs on any Linux distribution.

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
