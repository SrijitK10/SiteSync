// ignore_for_file: avoid_print
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../models/user_role.dart';
import '../services/notification_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? currentUser;

  AuthState({this.isAuthenticated = false, this.isLoading = false, this.currentUser});
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _tryRestoreSession();
    return AuthState(isLoading: true);
  }

  Future<void> _tryRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      if (token == null) {
        state = AuthState();
        return;
      }

      // Validate token by calling /auth/me
      final res = await apiClient.get('/auth/me');
      final userData = res.data;

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

      // Sync FCM token
      await _updateFcmToken();
    } catch (e) {
      // Token expired or invalid — clear it
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt');
      state = AuthState();
      print('Session restore failed: $e');
    }
  }

  Future<void> loginWithFirebaseToken(String idToken, {String? name}) async {
    try {
      final res = await apiClient.post('/auth/firebase-login', data: {
        'idToken': idToken,
        if (name != null && name.isNotEmpty) 'name': name,
      });
      final token = res.data['accessToken'];
      final userData = res.data['user'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', token);
      
      UserRole fetchedRole = UserRole.values.firstWhere(
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
          role: fetchedRole
        ),
      );

      // Sync FCM token
      await _updateFcmToken();
    } catch (e) {
      print('Error during Firebase login: $e');
      throw Exception('Login Error: $e');
    }
  }

  Future<void> loginWithPassword(String email, String password) async {
    try {
      final res = await apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _handleAuthResponse(res.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerWithPassword(String email, String password, String name) async {
    try {
      final res = await apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });
      await _handleAuthResponse(res.data);
    } catch (e) {
      rethrow;
    }
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt', token);

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

    // Sync FCM token
    await _updateFcmToken();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
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
