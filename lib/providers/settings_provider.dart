import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app-wide settings persisted to SharedPreferences.
///
/// API keys can be baked in at build time via `--dart-define`:
///   flutter run --dart-define=RAWG_API_KEY=your_key
/// Users can still override in Settings. The build-time key is the fallback.
class SettingsProvider extends ChangeNotifier {
  static const _scaleKey = 'ui_scale';
  static const _rawgApiKeyKey = 'rawg_api_key';
  static const _sc64EnabledKey = 'sc64_enabled';
  static const _sc64BinaryPathKey = 'sc64_binary_path';
  static const _romLibraryDirKey = 'rom_library_dir';
  static const _backdropEnabledKey = 'backdrop_enabled';
  static const _backdropPlaybackKey = 'backdrop_playback';
  static const _backdropBlurSigmaKey = 'backdrop_blur_sigma';
  static const _backdropScrimOpacityKey = 'backdrop_scrim_opacity';

  /// Build-time API key set via --dart-define=RAWG_API_KEY=...
  static const _builtInRawgKey = String.fromEnvironment('RAWG_API_KEY');
  static const double defaultScale = 1.0;
  static const double minScale = 0.8;
  static const double maxScale = 1.6;

  static const double defaultBackdropBlurSigma = 16.0;
  static const double defaultBackdropScrimOpacity = 0.65;
  static const BackdropPlayback defaultBackdropPlayback =
      BackdropPlayback.shuffle;

  double _uiScale = defaultScale;
  double get uiScale => _uiScale;

  String _userRawgApiKey = '';

  /// The effective API key: user override takes priority, then built-in.
  String get rawgApiKey =>
      _userRawgApiKey.isNotEmpty ? _userRawgApiKey : _builtInRawgKey;

  /// The user's personal key (never exposes the built-in key).
  String get userRawgApiKey => _userRawgApiKey;

  /// Whether a built-in key is configured (so UI can say "key provided").
  bool get hasBuiltInRawgKey => _builtInRawgKey.isNotEmpty;

  // --- SummerCart64 integration ---

  bool _sc64Enabled = false;
  bool get sc64Enabled => _sc64Enabled;

  String _sc64BinaryPath = '';

  /// Path to the sc64deployer binary. Empty string means "use PATH".
  String get sc64BinaryPath => _sc64BinaryPath;

  String _romLibraryDir = '';

  /// Directory where picked ROMs get copied. Empty string means "use the
  /// default `<appdocs>/roms/` location".
  String get romLibraryDir => _romLibraryDir;

  // --- Backdrop rendering ---

  bool _backdropEnabled = false;
  bool get backdropEnabled => _backdropEnabled;

  BackdropPlayback _backdropPlayback = defaultBackdropPlayback;
  BackdropPlayback get backdropPlayback => _backdropPlayback;

  double _backdropBlurSigma = defaultBackdropBlurSigma;
  double get backdropBlurSigma => _backdropBlurSigma;

  double _backdropScrimOpacity = defaultBackdropScrimOpacity;
  double get backdropScrimOpacity => _backdropScrimOpacity;

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _uiScale = _prefs?.getDouble(_scaleKey) ?? defaultScale;
    _userRawgApiKey = _prefs?.getString(_rawgApiKeyKey) ?? '';
    _sc64Enabled = _prefs?.getBool(_sc64EnabledKey) ?? false;
    _sc64BinaryPath = _prefs?.getString(_sc64BinaryPathKey) ?? '';
    _romLibraryDir = _prefs?.getString(_romLibraryDirKey) ?? '';
    _backdropEnabled = _prefs?.getBool(_backdropEnabledKey) ?? false;
    _backdropPlayback = BackdropPlayback.fromName(
        _prefs?.getString(_backdropPlaybackKey) ?? defaultBackdropPlayback.name);
    _backdropBlurSigma =
        _prefs?.getDouble(_backdropBlurSigmaKey) ?? defaultBackdropBlurSigma;
    _backdropScrimOpacity = _prefs?.getDouble(_backdropScrimOpacityKey) ??
        defaultBackdropScrimOpacity;
    notifyListeners();
  }

  Future<void> setUiScale(double scale) async {
    _uiScale = scale.clamp(minScale, maxScale);
    await _prefs?.setDouble(_scaleKey, _uiScale);
    notifyListeners();
  }

  Future<void> setRawgApiKey(String key) async {
    _userRawgApiKey = key.trim();
    await _prefs?.setString(_rawgApiKeyKey, _userRawgApiKey);
    notifyListeners();
  }

  Future<void> setSc64Enabled(bool enabled) async {
    _sc64Enabled = enabled;
    await _prefs?.setBool(_sc64EnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setSc64BinaryPath(String path) async {
    _sc64BinaryPath = path.trim();
    await _prefs?.setString(_sc64BinaryPathKey, _sc64BinaryPath);
    notifyListeners();
  }

  Future<void> setRomLibraryDir(String dir) async {
    _romLibraryDir = dir.trim();
    await _prefs?.setString(_romLibraryDirKey, _romLibraryDir);
    notifyListeners();
  }

  Future<void> setBackdropEnabled(bool enabled) async {
    _backdropEnabled = enabled;
    await _prefs?.setBool(_backdropEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setBackdropPlayback(BackdropPlayback mode) async {
    _backdropPlayback = mode;
    await _prefs?.setString(_backdropPlaybackKey, mode.name);
    notifyListeners();
  }

  Future<void> setBackdropBlurSigma(double sigma) async {
    _backdropBlurSigma = sigma.clamp(0.0, 40.0);
    await _prefs?.setDouble(_backdropBlurSigmaKey, _backdropBlurSigma);
    notifyListeners();
  }

  Future<void> setBackdropScrimOpacity(double opacity) async {
    _backdropScrimOpacity = opacity.clamp(0.0, 1.0);
    await _prefs?.setDouble(_backdropScrimOpacityKey, _backdropScrimOpacity);
    notifyListeners();
  }
}

/// How the game-detail backdrop picks between multiple backdrop files.
enum BackdropPlayback {
  /// Pick one at random on every detail-page entry.
  shuffle,

  /// Crossfade through them in order, looping.
  cycle;

  static BackdropPlayback fromName(String name) {
    return BackdropPlayback.values.firstWhere(
      (p) => p.name == name,
      orElse: () => BackdropPlayback.shuffle,
    );
  }
}
