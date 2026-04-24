import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/desktop_section_shell.dart';
import '../services/platform_utils.dart';
import '../state/users_provider.dart';
import '../state/auth_provider.dart';
import '../services/api_client.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  void _showAddUserBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'site_manager';
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final phone = phoneController.text.trim();

              if (name.isEmpty || (email.isEmpty && phone.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add a name and either an email or phone number.'),
                  ),
                );
                return;
              }

              setSheetState(() => isSubmitting = true);
              try {
                await apiClient.post(
                  '/users',
                  data: {
                    'name': name,
                    if (email.isNotEmpty) 'email': email,
                    if (phone.isNotEmpty) 'phone': phone,
                    'role': selectedRole,
                  },
                );
                ref.invalidate(usersProvider);
                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Teammate added successfully.')),
                );
              } on DioException catch (error) {
                if (!sheetContext.mounted) return;
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(extractErrorMessage(error))),
                );
              } catch (error) {
                if (!sheetContext.mounted) return;
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text('Failed to add teammate: $error')),
                );
              } finally {
                if (sheetContext.mounted) {
                  setSheetState(() => isSubmitting = false);
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.desktopPaneDecoration(context, radius: 28),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add teammate',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a team profile and assign the starting role.',
                          style: AppTheme.body.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'FULL NAME',
                          hint: 'Enter the teammate name',
                          controller: nameController,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'EMAIL',
                          hint: 'name@example.com',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'PHONE',
                          hint: '+91...',
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        Text('ROLE', style: AppTheme.label),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'super_admin',
                              child: Text('Super Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'site_manager',
                              child: Text('Site Manager'),
                            ),
                            DropdownMenuItem(
                              value: 'viewer',
                              child: Text('Viewer'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setSheetState(() => selectedRole = value);
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'Create teammate',
                          isLoading: isSubmitting,
                          onPressed: submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProjectAssignmentSheet(BuildContext context, User user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProjectAssignmentSheet(user: user),
    ).then((_) => ref.invalidate(usersProvider));
  }

  Future<void> _deleteUser(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete teammate'),
          content: Text('Remove ${user.name} from the workspace?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await apiClient.delete('/users/${user.id}');
      ref.invalidate(usersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} removed from the workspace.')),
      );
    } on DioException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(extractErrorMessage(error))),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete teammate: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final currentUser = ref.watch(authProvider).currentUser;
    final isWindows = isWindowsDesktop;
    final canManageUsers = currentUser?.role.isAdmin ?? false;
    final canDeleteUsers = currentUser?.role.canDelete ?? false;

    Widget buildUserTile(User user) {
      final isSelf = currentUser != null && user.id == currentUser.id;
      final canManageAccess =
          canManageUsers && !user.role.isAdmin && !isSelf;

      Future<void> updateRole(String? newRole) async {
        if (!canManageUsers || isSelf || newRole == null || newRole == user.role.value) {
          return;
        }

        try {
          await apiClient.patch(
            '/users/${user.id}',
            data: {'role': newRole},
          );
          ref.invalidate(usersProvider);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Role updated successfully.')),
          );
        } on DioException catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(extractErrorMessage(error))),
          );
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update role: $error')),
          );
        }
      }

      final roleControl = canManageUsers && !isSelf
          ? DropdownButton<String>(
              value: user.role.value,
              style: AppTheme.label.copyWith(
                color: AppTheme.primary,
                fontSize: isWindows ? 12 : 10,
              ),
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: AppTheme.primary,
                size: 20,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'super_admin',
                  child: Text('SUPER ADMIN'),
                ),
                DropdownMenuItem(
                  value: 'admin',
                  child: Text('ADMIN'),
                ),
                DropdownMenuItem(
                  value: 'site_manager',
                  child: Text('SITE MANAGER'),
                ),
                DropdownMenuItem(
                  value: 'viewer',
                  child: Text('VIEWER'),
                ),
              ],
              onChanged: updateRole,
            )
          : Chip(
              label: Text(user.role.value.toUpperCase()),
              labelStyle: AppTheme.label,
              backgroundColor: AppTheme.background,
            );

      if (isWindows) {
        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: canManageAccess
              ? () => _showProjectAssignmentSheet(context, user)
              : null,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.desktopPaneDecoration(context, radius: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accent,
                  radius: 24,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(color: AppTheme.surface),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.phone ?? user.email ?? '',
                        style: AppTheme.body.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.background.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              user.role.value.toUpperCase(),
                              style: AppTheme.label,
                            ),
                          ),
                          if (canManageAccess)
                            OutlinedButton.icon(
                              onPressed: () => _showProjectAssignmentSheet(context, user),
                              icon: const Icon(Icons.folder_shared),
                              label: const Text('Project access'),
                            ),
                          if (canDeleteUsers && !isSelf)
                            OutlinedButton.icon(
                              onPressed: () => _deleteUser(context, user),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 150),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: roleControl,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListTile(
        tileColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.accent,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(color: AppTheme.surface),
          ),
        ),
        title: Text(
          user.name,
          style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          user.phone ?? user.email ?? '',
          style: AppTheme.label.copyWith(
            textBaseline: TextBaseline.alphabetic,
          ),
        ),
        onTap: canManageAccess
            ? () => _showProjectAssignmentSheet(context, user)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canManageAccess)
              IconButton(
                icon: Icon(
                  Icons.folder_shared,
                  color: AppTheme.primary,
                  size: 20,
                ),
                tooltip: 'Manage Project Access',
                onPressed: () => _showProjectAssignmentSheet(context, user),
              ),
            if (canDeleteUsers && !isSelf)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                tooltip: 'Delete user',
                onPressed: () => _deleteUser(context, user),
              ),
            roleControl,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Team Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(usersProvider),
          ),
        ],
      ),
      floatingActionButton: canManageUsers && !isWindows
          ? FloatingActionButton(
              backgroundColor: AppTheme.primary,
              onPressed: () => _showAddUserBottomSheet(context),
              child: Icon(Icons.add, color: AppTheme.surface),
            )
          : null,
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final adminCount = users.where((user) => user.role.isAdmin).length;
          final restrictedCount = users.where((user) => !user.role.isAdmin).length;

          final userList = ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => buildUserTile(users[index]),
          );

          if (!isWindows) {
            return userList;
          }

          final actions = <Widget>[
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(usersProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh list'),
            ),
          ];

          if (canManageUsers) {
            actions.add(
              FilledButton.icon(
                onPressed: () => _showAddUserBottomSheet(context),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add teammate'),
              ),
            );
          }

          return DesktopSectionShell(
            eyebrow: 'Team access',
            title: 'Manage roles and project access without leaving the desktop workspace',
            subtitle:
                'Review who has access, update responsibilities, and assign project visibility from one place.',
            actions: actions,
            metrics: [
              DesktopSectionMetric(
                label: 'Team members',
                value: users.length.toString(),
                icon: Icons.groups_rounded,
              ),
              DesktopSectionMetric(
                label: 'Admin roles',
                value: adminCount.toString(),
                icon: Icons.admin_panel_settings_outlined,
              ),
              DesktopSectionMetric(
                label: 'Restricted roles',
                value: restrictedCount.toString(),
                icon: Icons.shield_outlined,
              ),
            ],
            child: userList,
          );
        },
      ),
    );
  }
}

// ── Project Assignment Bottom Sheet (Stateful) ───────────────────

class _ProjectAssignmentSheet extends StatefulWidget {
  final User user;
  const _ProjectAssignmentSheet({required this.user});

  @override
  State<_ProjectAssignmentSheet> createState() =>
      _ProjectAssignmentSheetState();
}

class _ProjectAssignmentSheetState extends State<_ProjectAssignmentSheet> {
  List<Map<String, dynamic>> _allProjects = [];
  Set<String> _assignedIds = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch all projects and user's current assignments in parallel
      final results = await Future.wait([
        apiClient.get('/projects'),
        apiClient.get('/projects/user/${widget.user.id}/assignments'),
      ]);

      final allProjects = (results[0].data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final assignedIds = (results[1].data as List)
          .map((e) => e.toString())
          .toSet();

      if (mounted) {
        setState(() {
          _allProjects = allProjects;
          _assignedIds = assignedIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load project assignments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    }
  }

  Future<void> _saveAssignments() async {
    setState(() => _isSaving = true);
    try {
      await apiClient.post(
        '/projects/user/${widget.user.id}/assignments',
        data: {'projectIds': _assignedIds.toList()},
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Access updated for ${widget.user.name}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.accent,
                    radius: 18,
                    child: Text(
                      widget.user.name.isNotEmpty
                          ? widget.user.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppTheme.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.name,
                          style: AppTheme.heading.copyWith(fontSize: 16),
                        ),
                        Text(
                          '${widget.user.role.value.toUpperCase()} • ${widget.user.displayIdentifier}',
                          style: AppTheme.label.copyWith(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Toggle which projects this user can access:',
                style: AppTheme.body.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // Project list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _allProjects.isEmpty
                    ? const Center(child: Text('No projects found.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _allProjects.length,
                        itemBuilder: (context, index) {
                          final project = _allProjects[index];
                          final projectId = project['id'] as String;
                          final isAssigned = _assignedIds.contains(projectId);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isAssigned
                                  ? AppTheme.primary.withValues(alpha: 0.08)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isAssigned
                                    ? AppTheme.primary.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              title: Text(
                                project['name'] ?? 'Unnamed',
                                style: AppTheme.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                project['location'] ?? '',
                                style: AppTheme.label.copyWith(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              value: isAssigned,
                              activeThumbColor: AppTheme.primary,
                              onChanged: (val) {
                                setState(() {
                                  if (val) {
                                    _assignedIds.add(projectId);
                                  } else {
                                    _assignedIds.remove(projectId);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),

              // Summary + Save button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_assignedIds.length} of ${_allProjects.length} projects assigned',
                      style: AppTheme.label.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (!_isLoading)
                    _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: AppTheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Save Access'),
                            onPressed: _saveAssignments,
                          ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
