import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client/api/client.dart';

class AuthNotifier extends StateNotifier<String?> {
  static const String _tokenKey = 'auth_token';
  bool _isLoading = true;

  AuthNotifier() : super(null) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      
      if (token != null) {
        state = token;
        ApiClient.setToken(token);
      } else {
        ApiClient.clearToken();
      }
      try {
        await ApiClient.getProfile();
      } catch (e) {
        if (e.toString().contains('401') || e.toString().contains('Требуется авторизация')) {
          await clearToken();
        } else {
          rethrow;
        }
      }
      await ApiClient.getProfile();
    } catch (e) {
    } finally {
      _isLoading = false;
    }
  }

  Future<void> setToken(String token) async {
    state = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    ApiClient.setToken(token);
    print('Token saved: ${token.substring(0, 20)}...');
  }

  Future<void> clearToken() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    ApiClient.clearToken();
    print('Token cleared');
  }

  bool get isAuthenticated => state != null && !_isLoading;
  bool get isLoading => _isLoading;
}

final authProvider = StateNotifierProvider<AuthNotifier, String?>((ref) {
  return AuthNotifier();
});

final authLoadingProvider = Provider<bool>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return authNotifier.isLoading;
});