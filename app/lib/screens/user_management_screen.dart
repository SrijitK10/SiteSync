import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../state/users_provider.dart';
import '../state/auth_provider.dart';
import '../services/api_client.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh role and user list as soon as the screen opens so an admin
    // who was promoted (or demoted) sees the current reality immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authProvider.notifier).refreshCurrentUser();
      if (!mounted) return;
      final fresh = ref.read(authProvider).currentUser;
      if (fresh == null || !fresh.role.isAdmin) {
        if (mounted) context.go('/projects');
        return;
      }
      ref.invalidate(usersProvider);
    });
  }

  void _showAddUserBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'site_manager';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add New Teammate', style: AppTheme.heading),
                  const SizedBox(height: 16),
                  AppTextField(label: 'NAME', hint: 'Rajesh Kumar', controller: nameController),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'PHONE NUMBER',
                    hint: '9876543210',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  // Role selector dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'ROLE',
                      labelStyle: AppTheme.label,
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'site_manager', child: Text('Site Manager')),
                      DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                    ],
                    onChanged: (val) {
                      if (val != null) selectedRole = val;
                    },
                  ),
                  const SizedBox(height: 24),
                  isSubmitting
                      ? const CircularProgressIndicator()
                      : AppButton(
                          text: 'Create User',
                          onPressed: () async {
                            if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                            setState(() => isSubmitting = true);
                            try {
                              final phone = '+91${phoneController.text.trim()}';
                              await apiClient.post('/users', data: {
                                'name': nameController.text.trim(),
                                'phone': phone,
                                'role': selectedRole,
                              });
                              if (context.mounted) {
                                Navigator.pop(context);
                                ref.invalidate(usersProvider);
                              }
                            } catch (e) {
                              setState(() => isSubmitting = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e', style: const TextStyle(color: Colors.red))));
                              }
                            }
                          },
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final usersAsync = ref.watch(usersProvider);
    final currentUser = authState.currentUser;
    final canEditRoles = currentUser != null && currentUser.role.isAdmin;

    // While auth is still loading or user is momentarily null during a
    // refresh, show a spinner instead of redirecting. Only redirect when
    // the user is definitively non-admin.
    if (authState.isLoading || currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!currentUser.role.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/projects');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manage Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(authProvider.notifier).refreshCurrentUser();
              ref.invalidate(usersProvider);
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showAddUserBottomSheet(context),
        child: const Icon(Icons.add, color: AppTheme.surface),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (users) {
          if (users.isEmpty) return const Center(child: Text('No users found.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                tileColor: AppTheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accent,
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.surface)),
                ),
                title: Text(user.name, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(user.phone ?? user.email ?? '', style: AppTheme.label.copyWith(textBaseline: TextBaseline.alphabetic)),
                trailing: canEditRoles && user.id != currentUser.id
                    ? DropdownButton<String>(
                        value: user.role.value,
                        style: AppTheme.label.copyWith(color: AppTheme.primary, fontSize: 10),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary, size: 20),
                        items: const [
                          DropdownMenuItem(value: 'super_admin', child: Text('SUPER ADMIN')),
                          DropdownMenuItem(value: 'admin', child: Text('ADMIN')),
                          DropdownMenuItem(value: 'site_manager', child: Text('SITE MANAGER')),
                          DropdownMenuItem(value: 'viewer', child: Text('VIEWER')),
                        ],
                        onChanged: (newRole) async {
                          if (newRole != null && newRole != user.role.value) {
                            try {
                              await apiClient.patch('/users/${user.id}', data: {'role': newRole});
                              ref.invalidate(usersProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated successfully.')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update role: $e', style: const TextStyle(color: Colors.red))));
                              }
                            }
                          }
                        },
                      )
                    : Chip(
                        label: Text(user.role.value.toUpperCase()),
                        labelStyle: AppTheme.label,
                        backgroundColor: AppTheme.background,
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
