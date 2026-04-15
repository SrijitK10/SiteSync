import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../state/projects_provider.dart';
import '../state/auth_provider.dart';
import '../services/api_client.dart';
import '../services/platform_utils.dart';
import '../l10n/app_localizations.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String projectId,
  ) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(l.deleteProject, style: AppTheme.heading),
        content: Text(l.deleteProjectWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await apiClient.delete('/projects/$projectId');
        ref.invalidate(projectsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.projectDeletedSuccess)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete project: $e')),
          );
        }
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;
    final l = AppLocalizations.of(context)!;

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
                  Text(l.changePassword, style: AppTheme.heading),
                  const SizedBox(height: 24),
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l.currentPassword,
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
                      labelText: l.newPassword,
                      hintText: l.newPasswordHint,
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
                      labelText: l.confirmNewPassword,
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
                          text: l.updatePassword,
                          onPressed: () async {
                            final oldPw = oldPasswordController.text;
                            final newPw = newPasswordController.text;
                            final confirmPw = confirmPasswordController.text;

                            if (oldPw.isEmpty || newPw.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.fillAllFields)),
                              );
                              return;
                            }
                            if (newPw.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.passwordMinLength)),
                              );
                              return;
                            }
                            if (newPw != confirmPw) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.passwordsDoNotMatch)),
                              );
                              return;
                            }

                            setState(() => isSubmitting = true);
                            try {
                              await ref
                                  .read(authProvider.notifier)
                                  .changePassword(oldPw, newPw);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l.passwordChangedSuccess),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(extractErrorMessage(e)),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted)
                                setState(() => isSubmitting = false);
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
    final l = AppLocalizations.of(context)!;

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
                  Text(l.createProject, style: AppTheme.heading),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: l.projectName,
                    hint: l.projectNameHint,
                    controller: nameController,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: l.projectLocation,
                    hint: l.projectLocationHint,
                    controller: locationController,
                  ),
                  const SizedBox(height: 32),
                  isSubmitting
                      ? const CircularProgressIndicator()
                      : AppButton(
                          text: l.commitToDatabase,
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;

                            setState(() => isSubmitting = true);
                            try {
                              await apiClient.post(
                                '/projects',
                                data: {
                                  'name': nameController.text.trim(),
                                  'location': locationController.text.trim(),
                                  'status': 'active',
                                },
                              );

                              ref.invalidate(projectsProvider);
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error adding project: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted)
                                setState(() => isSubmitting = false);
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
    final canManageProjects = user != null && user.role.isAdmin;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        centerTitle: false,
        title: Image.asset('assets/images/rppl.png', height: 36),
        actions: [
          if (canManageProjects)
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: l.manageUsers,
              onPressed: () => context.push('/users'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l.refresh,
            onPressed: () {
              ref.read(authProvider.notifier).refreshCurrentUser();
              ref.invalidate(projectsProvider);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'change_password') {
                _showChangePasswordDialog(context, ref);
              } else if (value == 'settings') {
                context.push('/settings');
              } else if (value == 'logout') {
                await ref.read(authProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              if (isApplePlatform)
                PopupMenuItem(
                  value: 'change_password',
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(l.changePassword),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(l.settings),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 20),
                    const SizedBox(width: 8),
                    Text(l.logOut),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: canManageProjects
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: () => _showAddProjectBottomSheet(context, ref),
              child: Icon(Icons.add, color: AppTheme.surface),
            )
          : null,
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
                Text(
                  l.connectionError,
                  style: AppTheme.heading.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: AppTheme.body,
                ),
              ],
            ),
          ),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return Center(child: Text(l.noProjectsFound));
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
                            child: Text(
                              p['name'] ?? l.untitled,
                              style: AppTheme.heading.copyWith(fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (canManageProjects)
                            GestureDetector(
                              onTap: () => _confirmDelete(
                                context,
                                ref,
                                p['id'].toString(),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p['location'] ?? '',
                            style: AppTheme.body.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
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
