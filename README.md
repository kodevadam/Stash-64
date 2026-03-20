# Stash 64

A retro game collection browser built with Flutter. Designed as a touchscreen kiosk app for Raspberry Pi — walk up to your game den, browse your collection by console, genre, or number of players, see cover art and screenshots, and find exactly where each game is stored.

## Features

- **Browse by console** — N64, SNES, Genesis, NES, PlayStation, Game Boy, Dreamcast, Atari, and any custom consoles you add
- **Filter by genre, player count, storage location** — find that perfect 4-player game night pick
- **Cover art display** — add box art or custom images for each game
- **Screenshots** — attach and browse in-game screenshots with fullscreen viewer
- **Storage locations** — track exactly where each game lives (Drawer 1, Shelf A, etc.)
- **Favorites** — star your top games and filter to favorites
- **Search** — instant search across your collection
- **Touch-optimized** — large tap targets (56dp), smooth scrolling, designed for touchscreen kiosks
- **Dark retro theme** — a warm dark UI with gold accents that fits the vibe

## Supported Platforms

| Platform | Status |
|----------|--------|
| Linux (x86_64) | Primary |
| Linux (ARM64/Raspberry Pi) | Primary |
| Windows | Supported |
| macOS | Supported |
| Android | Supported |
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

### Build as AppImage

```bash
# Install appimagetool first:
# https://github.com/AppImage/appimagetool/releases

./scripts/build-appimage.sh
```

This produces a portable `Stash_64-<arch>.AppImage` that runs on any Linux distribution.

### Raspberry Pi Setup

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

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── game.dart             # Game data model
│   ├── game_console.dart     # Console data model
│   └── filter_state.dart     # Filter/sort state
├── data/
│   ├── database_helper.dart  # SQLite database layer
│   └── sample_data.dart      # First-launch seed data
├── providers/
│   └── game_provider.dart    # State management (ChangeNotifier)
├── screens/
│   ├── home_screen.dart      # Main grid browser
│   ├── game_detail_screen.dart  # Game info + screenshots
│   └── game_form_screen.dart # Add/edit game form
├── widgets/
│   ├── game_card.dart        # Grid card with cover art
│   ├── filter_drawer.dart    # Filter/sort side drawer
│   └── search_bar_widget.dart
└── theme/
    └── app_theme.dart        # Dark retro theme
```

## Data Storage

- **Database**: SQLite via `sqflite_common_ffi` (works natively on Linux/ARM)
- **Images**: Cover art and screenshots are copied to the app's documents directory
- **Location**: `~/.local/share/stash_64/` on Linux

## License

MIT
