import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app-wide settings persisted to SharedPreferences.
class SettingsProvider extends ChangeNotifier {
  static const _scaleKey = 'ui_scale';
  static const _rawgApiKeyKey = 'rawg_api_key';
  static const double defaultScale = 1.0;
  static const double minScale = 0.8;
  static const double maxScale = 1.6;

  double _uiScale = defaultScale;
  double get uiScale => _uiScale;

  String _rawgApiKey = '';
  String get rawgApiKey => _rawgApiKey;

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _uiScale = _prefs?.getDouble(_scaleKey) ?? defaultScale;
    _rawgApiKey = _prefs?.getString(_rawgApiKeyKey) ?? '';
    notifyListeners();
  }

  Future<void> setUiScale(double scale) async {
    _uiScale = scale.clamp(minScale, maxScale);
    await _prefs?.setDouble(_scaleKey, _uiScale);
    notifyListeners();
  }

  Future<void> setRawgApiKey(String key) async {
    _rawgApiKey = key.trim();
    await _prefs?.setString(_rawgApiKeyKey, _rawgApiKey);
    notifyListeners();
  }
}
