import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../state/projects_provider.dart';
import '../state/auth_provider.dart';
import '../models/user_role.dart';
import '../services/api_client.dart';
import '../services/platform_utils.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Delete Project', style: AppTheme.heading),
        content: const Text('Are you sure you want to permanently delete this project? All associated tasks, calendars, and attendance records will be completely erased.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await apiClient.delete('/projects/$projectId');
        ref.invalidate(projectsProvider);
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project structure fully deleted.')));
        }
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete project: $e')));
        }
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
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
                  Text('Change Password', style: AppTheme.heading),
                  const SizedBox(height: 24),
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Min. 6 characters',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  isSubmitting
                    ? const CircularProgressIndicator()
                    : AppButton(
                        text: 'Update Password',
                        onPressed: () async {
                          final oldPw = oldPasswordController.text;
                          final newPw = newPasswordController.text;
                          final confirmPw = confirmPasswordController.text;

                          if (oldPw.isEmpty || newPw.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in all fields')),
                            );
                            return;
                          }
                          if (newPw.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('New password must be at least 6 characters')),
                            );
                            return;
                          }
                          if (newPw != confirmPw) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Passwords do not match')),
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);
                          try {
                            await ref.read(authProvider.notifier).changePassword(oldPw, newPw);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password changed successfully')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(extractErrorMessage(e))),
                              );
                            }
                          } finally {
                            if (context.mounted) setState(() => isSubmitting = false);
                          }
                        },
                      ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddProjectBottomSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
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
                  Text('Create Centralized Project', style: AppTheme.heading),
                  const SizedBox(height: 16),
                  AppTextField(label: 'NAME', hint: 'E.g. Downtown Plaza', controller: nameController),
                  const SizedBox(height: 16),
                  AppTextField(label: 'LOCATION', hint: '123 Main St', controller: locationController),
                  const SizedBox(height: 32),
                  isSubmitting
                    ? const CircularProgressIndicator()
                    : AppButton(
                        text: 'Commit to Database',
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;
                          
                          setState(() => isSubmitting = true);
                          try {
                            await apiClient.post('/projects', data: {
                              'name': nameController.text.trim(),
                              'location': locationController.text.trim(),
                              'status': 'active',
                            });
                            
                            ref.invalidate(projectsProvider);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding project: $e')));
                            }
                          } finally {
                            if (context.mounted) setState(() => isSubmitting = false);
                          }
                        },
                      ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final user = ref.watch(authProvider).currentUser;
    final canManageProjects = user?.role == UserRole.superAdmin || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        centerTitle: false,
        title: Image.asset('assets/images/rppl.png', height: 36),
        actions: [
          if (canManageProjects)
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Manage Users',
              onPressed: () => context.push('/users'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Projects',
            onPressed: () => ref.invalidate(projectsProvider),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'change_password') {
                _showChangePasswordDialog(context, ref);
              } else if (value == 'logout') {
                await ref.read(authProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              if (isApplePlatform)
                const PopupMenuItem(
                  value: 'change_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Change Password'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Log Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: canManageProjects ? FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showAddProjectBottomSheet(context, ref),
        child: const Icon(Icons.add, color: AppTheme.surface),
      ) : null,
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Connection Error', style: AppTheme.heading.copyWith(color: Colors.red)),
                const SizedBox(height: 8),
                Text(err.toString(), textAlign: TextAlign.center, style: AppTheme.body),
              ],
            ),
          ),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(child: Text('No projects found. Add one above!'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = projects[index];
              return GestureDetector(
                onTap: () => context.push(
                  '/projects/${p['id']}', 
                  extra: {'name': p['name'], 'location': p['location']},
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(p['name'] ?? 'Unnamed', style: AppTheme.heading.copyWith(fontSize: 18), overflow: TextOverflow.ellipsis),
                          ),
                          if (canManageProjects)
                            GestureDetector(
                              onTap: () => _confirmDelete(context, ref, p['id'].toString()),
                              child: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textSecondary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(p['location'] ?? 'No Location', style: AppTheme.body.copyWith(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
