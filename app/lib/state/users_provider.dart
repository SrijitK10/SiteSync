import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../models/user_role.dart';

class User {
  final String id;
  final String name;
  final String phone;
  final UserRole role;

  User({required this.id, required this.name, required this.phone, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.value == json['role'],
        orElse: () => UserRole.viewer,
      ),
    );
  }
}

final usersProvider = FutureProvider<List<User>>((ref) async {
  try {
    final response = await apiClient.get('/users');
    final List<dynamic> data = response.data;
    return data.map((json) => User.fromJson(json)).toList();
  } catch (e) {
    throw Exception('Failed to load active users');
  }
});
