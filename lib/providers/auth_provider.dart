import 'package:flutter/foundation.dart';

import '../data/api_repository.dart';

/// Authentication state for the web app.
///
/// On app load, checks backend session via /api/auth/me.
/// Sign-in state is determined by the backend, never by frontend memory.
/// The frontend is a messenger, not a judge.
class AuthProvider extends ChangeNotifier {
  final ApiRepository _api;

  AuthProvider(this._api);

  bool _isLoading = true;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get displayName => _user?['displayName'] as String?;
  String? get avatarUrl => _user?['avatarUrl'] as String?;
  String? get email => _user?['email'] as String?;

  /// Check existing session on app startup.
  /// Determines auth state from backend session, not frontend memory.
  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _api.checkSession();
      if (result != null) {
        _user = result['user'] as Map<String, dynamic>?;
        _isAuthenticated = _user != null;
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (_) {
      _isAuthenticated = false;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Send Google ID token to backend for server-side verification.
  /// Backend creates session and sets HttpOnly cookie.
  Future<void> signInWithGoogle(String idToken) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _api.signInWithGoogle(idToken);
      _user = result['user'] as Map<String, dynamic>?;
      _isAuthenticated = _user != null;
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout — revoke session on backend, clear local state.
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Best-effort logout
    }
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

  /// Delete account and all data.
  Future<void> deleteAccount() async {
    await _api.deleteAccount();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
