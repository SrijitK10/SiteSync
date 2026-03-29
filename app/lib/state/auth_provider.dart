// ignore_for_file: avoid_print
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../models/user_role.dart';

class AuthState {
  final bool isAuthenticated;
  final User? currentUser;

  AuthState({this.isAuthenticated = false, this.currentUser});
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  Future<void> login(String email, String password) async {
    try {
      final res = await apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = res.data['accessToken'];
      final userData = res.data['user'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', token);
      
      // Parse precise Role Enum from backend string representation
      UserRole fetchedRole = UserRole.values.firstWhere(
        (r) => r.value == userData['role'],
        orElse: () => UserRole.viewer,
      );

      state = AuthState(
        isAuthenticated: true,
        currentUser: User(
          id: userData['id'], 
          name: userData['name'], 
          email: userData['email'], 
          role: fetchedRole
        ),
      );
    } catch (e) {
      print('DioError inside Login pipeline: $e');
      throw Exception('Connection/Login Error: $e');
    }
  }

  void loginFakeUser(UserRole role) {
    state = AuthState(
      isAuthenticated: true,
      currentUser: User(id: '1', name: 'Test User', email: 'test@sitesync.com', role: role),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
