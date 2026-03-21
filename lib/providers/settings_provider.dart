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

  /// Build-time API key set via --dart-define=RAWG_API_KEY=...
  static const _builtInRawgKey = String.fromEnvironment('RAWG_API_KEY');
  static const double defaultScale = 1.0;
  static const double minScale = 0.8;
  static const double maxScale = 1.6;

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

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _uiScale = _prefs?.getDouble(_scaleKey) ?? defaultScale;
    _userRawgApiKey = _prefs?.getString(_rawgApiKeyKey) ?? '';
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
}
