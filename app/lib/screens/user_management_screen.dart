import 'package:dio/dio.dart';
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
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(usersProvider);
    });
  }

  // ── Add User ────────────────────────────────────────────────────
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
                  AppTextField(
                    label: 'NAME',
                    hint: 'Rajesh Kumar',
                    controller: nameController,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'PHONE NUMBER',
                    hint: '9876543210',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
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
                      DropdownMenuItem(
                        value: 'site_manager',
                        child: Text('Site Manager'),
                      ),
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
                            if (nameController.text.isEmpty ||
                                phoneController.text.isEmpty)
                              return;
                            setState(() => isSubmitting = true);
                            try {
                              final phone = '+91${phoneController.text.trim()}';
                              await apiClient.post(
                                '/users',
                                data: {
                                  'name': nameController.text.trim(),
                                  'phone': phone,
                                  'role': selectedRole,
                                },
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ref.invalidate(usersProvider);
                              }
                            } catch (e) {
                              setState(() => isSubmitting = false);
                              String msg = 'Failed to create user';
                              if (e is DioException) {
                                final data = e.response?.data;
                                if (data is Map && data['message'] != null) {
                                  msg = data['message'].toString();
                                }
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      msg,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
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

  // ── Project Assignment Sheet ────────────────────────────────────
  void _showProjectAssignmentSheet(BuildContext context, User user) async {
    // Fetch all projects and user's current assignments in parallel
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return _ProjectAssignmentSheet(user: user);
      },
    );
  }

  // ── Delete User ────────────────────────────────────────────────
  Future<void> _deleteUser(BuildContext context, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${user.name}?'),
        content: const Text(
          'This action cannot be undone. The user will lose all access.',
        ),
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
    if (confirmed != true) return;
    try {
      await apiClient.delete('/users/${user.id}');
      ref.invalidate(usersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User deleted.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final usersAsync = ref.watch(usersProvider);
    final currentUser = authState.currentUser;
    final canEditRoles = currentUser != null && currentUser.role.isAdmin;

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
            onPressed: () {
              ref.invalidate(usersProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showAddUserBottomSheet(context),
        child: Icon(Icons.add, color: AppTheme.surface),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (users) {
          if (users.isEmpty)
            return const Center(child: Text('No users found.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              final isSelf = user.id == currentUser.id;
              final isNonAdmin =
                  user.role.value == 'site_manager' ||
                  user.role.value == 'viewer';
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
                // Tap to manage project access for non-admin users
                onTap: canEditRoles && isNonAdmin && !isSelf
                    ? () => _showProjectAssignmentSheet(context, user)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Project access indicator for non-admins
                    if (canEditRoles && isNonAdmin && !isSelf)
                      IconButton(
                        icon: Icon(
                          Icons.folder_shared,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                        tooltip: 'Manage Project Access',
                        onPressed: () =>
                            _showProjectAssignmentSheet(context, user),
                      ),
                    // Role dropdown or chip
                    if (canEditRoles && !isSelf)
                      DropdownButton<String>(
                        value: user.role.value,
                        style: AppTheme.label.copyWith(
                          color: AppTheme.primary,
                          fontSize: 10,
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
                        onChanged: (newRole) async {
                          if (newRole != null && newRole != user.role.value) {
                            try {
                              await apiClient.patch(
                                '/users/${user.id}',
                                data: {'role': newRole},
                              );
                              ref.invalidate(usersProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Role updated successfully.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to update role: $e',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      )
                    else
                      Chip(
                        label: Text(user.role.value.toUpperCase()),
                        labelStyle: AppTheme.label,
                        backgroundColor: AppTheme.background,
                      ),
                  ],
                ),
              );
            },
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
                    color: AppTheme.textSecondary.withOpacity(0.3),
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
                                  ? AppTheme.primary.withOpacity(0.08)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isAssigned
                                    ? AppTheme.primary.withOpacity(0.3)
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
                              activeColor: AppTheme.primary,
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
