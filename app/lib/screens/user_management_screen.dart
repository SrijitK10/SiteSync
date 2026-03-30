import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../state/users_provider.dart';
import '../services/api_client.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  void _showAddUserBottomSheet(BuildContext context, WidgetRef ref) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manage Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(usersProvider),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showAddUserBottomSheet(context, ref),
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
                trailing: Chip(
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
