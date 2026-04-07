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
    } else {
      state = AuthState(isLoading: true);
    }

    // STEP 2: Validate in background so the server-side role is authoritative.
    final refreshed = await _fetchAndApplyCurrentUser();
    if (!refreshed && cachedUser == null) {
      // No cache and validation failed — token is likely invalid.
      await prefs.remove('jwt');
      await prefs.remove(_kCachedUserKey);
      await setJwt(null);
      state = AuthState();
    }

    if (refreshed) {
      // Sync FCM token opportunistically once the session is confirmed valid.
      _updateFcmToken();
    }
  }

  /// Re-fetches the current user from the backend and updates both the
  /// in-memory state and the local cache. Returns true on success.
  ///
  /// Call this whenever the client's role/identity might be stale — e.g. on
  /// app resume, before navigating to an admin-only screen, or after a
  /// 401/403 from a privileged endpoint. The backend always returns the
  /// user's live role from the database, so calling this reliably corrects
  /// any stale cached role on the device.
  Future<bool> refreshCurrentUser() async {
    return _fetchAndApplyCurrentUser();
  }

  Future<bool> _fetchAndApplyCurrentUser() async {
    try {
      final res = await apiClient.get('/auth/me');
      final userData = res.data as Map<String, dynamic>;

      final id = userData['id']?.toString();
      if (id == null || id.isEmpty) {
        print('Session validation: server returned no user id');
        return false;
      }

      final fetchedRole = UserRole.values.firstWhere(
        (r) => r.value == userData['role'],
        orElse: () => UserRole.viewer,
      );

      final user = User(
        id: id,
        name: (userData['name'] ?? '').toString(),
        phone: userData['phone']?.toString(),
        email: userData['email']?.toString(),
        role: fetchedRole,
      );

      final prefs = await SharedPreferences.getInstance();
      await _saveCachedUser(prefs, userData);
      state = AuthState(isAuthenticated: true, currentUser: user);
      return true;
    } catch (e) {
      print('Session validation failed: $e');
      return false;
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
