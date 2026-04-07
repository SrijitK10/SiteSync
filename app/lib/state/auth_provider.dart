// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../models/user_role.dart';
import '../services/notification_service.dart';

const _kCachedUserKey = 'cached_user';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? currentUser;

  AuthState({this.isAuthenticated = false, this.isLoading = false, this.currentUser});
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return _bootstrap();
  }

  // Synchronously-ish bootstraps state: returns an initial state, then
  // asynchronously validates in the background.
  AuthState _bootstrap() {
    // Kick off async restore — doesn't block the build.
    Future.microtask(_tryRestoreSession);
    return AuthState(isLoading: true);
  }

  Future<void> _tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    if (token == null) {
      state = AuthState();
      return;
    }

    // STEP 1: Show cached user IMMEDIATELY so the UI doesn't wait on the server.
    final cachedUser = _loadCachedUser(prefs);
    if (cachedUser != null) {
      state = AuthState(isAuthenticated: true, currentUser: cachedUser);
    }

    // STEP 2: Validate in background. UI is already usable if we had a cache.
    try {
      final res = await apiClient.get('/auth/me');
      final userData = res.data;

      final fetchedRole = UserRole.values.firstWhere(
        (r) => r.value == userData['role'],
        orElse: () => UserRole.viewer,
      );

      final user = User(
        id: userData['id'],
        name: userData['name'],
        phone: userData['phone'],
        email: userData['email'],
        role: fetchedRole,
      );

      await _saveCachedUser(prefs, userData);
      state = AuthState(isAuthenticated: true, currentUser: user);

      // Sync FCM token opportunistically
      _updateFcmToken();
    } catch (e) {
      // If we had a cached user, keep them signed in — they're offline or
      // the server is still cold. Don't kick them to login.
      if (cachedUser != null) {
        print('Session validation failed, keeping cached session: $e');
        return;
      }
      // No cache and validation failed — token is likely invalid.
      await prefs.remove('jwt');
      await prefs.remove(_kCachedUserKey);
      await setJwt(null);
      state = AuthState();
      print('Session restore failed: $e');
    }
  }

  User? _loadCachedUser(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_kCachedUserKey);
      if (raw == null) return null;
      final Map<String, dynamic> userData = jsonDecode(raw);
      final role = UserRole.values.firstWhere(
        (r) => r.value == userData['role'],
        orElse: () => UserRole.viewer,
      );
      return User(
        id: userData['id'],
        name: userData['name'],
        phone: userData['phone'],
        email: userData['email'],
        role: role,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCachedUser(SharedPreferences prefs, Map<String, dynamic> userData) async {
    await prefs.setString(_kCachedUserKey, jsonEncode({
      'id': userData['id'],
      'name': userData['name'],
      'phone': userData['phone'],
      'email': userData['email'],
      'role': userData['role'],
    }));
  }

  Future<void> loginWithFirebaseToken(String idToken, {String? name}) async {
    try {
      final res = await apiClient.post('/auth/firebase-login', data: {
        'idToken': idToken,
        if (name != null && name.isNotEmpty) 'name': name,
      });
      await _handleAuthResponse(res.data);
    } catch (e) {
      print('Error during Firebase login: $e');
      throw Exception('Login Error: $e');
    }
  }

  Future<void> loginWithPassword(String email, String password) async {
    final res = await apiClient.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _handleAuthResponse(res.data);
  }

  Future<void> registerWithPassword(String email, String password, String name) async {
    final res = await apiClient.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
    });
    await _handleAuthResponse(res.data);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await apiClient.post('/auth/change-password', data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    final token = data['accessToken'];
    final userData = data['user'];

    await setJwt(token);
    final prefs = await SharedPreferences.getInstance();
    await _saveCachedUser(prefs, userData);

    final fetchedRole = UserRole.values.firstWhere(
      (r) => r.value == userData['role'],
      orElse: () => UserRole.viewer,
    );

    state = AuthState(
      isAuthenticated: true,
      currentUser: User(
        id: userData['id'],
        name: userData['name'],
        phone: userData['phone'],
        email: userData['email'],
        role: fetchedRole,
      ),
    );

    _updateFcmToken();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCachedUserKey);
    await setJwt(null);
    state = AuthState();
  }

  Future<void> _updateFcmToken() async {
    try {
      final token = await NotificationService().getToken();
      if (token != null) {
        await apiClient.patch('/users/me/fcm-token', data: {'fcm_token': token});
      }
    } catch (e) {
      print('Failed to update FCM token on backend: $e');
    }
  }

  void setAuth(AuthState newState) {
    state = newState;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
