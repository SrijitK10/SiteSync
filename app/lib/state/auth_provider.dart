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

  Future<void> loginWithFirebaseToken(String idToken) async {
    try {
      final res = await apiClient.post('/auth/firebase-login', data: {
        'idToken': idToken,
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
          role: fetchedRole
        ),
      );
    } catch (e) {
      print('Error during Firebase login: $e');
      throw Exception('Login Error: $e');
    }
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
