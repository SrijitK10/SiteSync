enum UserRole {
  superAdmin('super_admin'),
  admin('admin'),
  siteManager('site_manager'),
  viewer('viewer');

  final String value;
  const UserRole(this.value);

  /// Helper methods requested in the original spec
  bool get canEdit => this == UserRole.superAdmin || this == UserRole.admin || this == UserRole.siteManager;
  bool get canDelete => this == UserRole.superAdmin || this == UserRole.admin;
  bool get isAdmin => this == UserRole.superAdmin || this == UserRole.admin;

  static UserRole fromString(String roleStr) {
    return UserRole.values.firstWhere((r) => r.value == roleStr, orElse: () => UserRole.viewer);
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  User({required this.id, required this.name, required this.email, required this.role});
}
