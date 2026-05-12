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
import '../state/unread_tracker_provider.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.projectDeletedSuccess)));
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
                              if (context.mounted) {
                                setState(() => isSubmitting = false);
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
                              if (context.mounted) {
                                setState(() => isSubmitting = false);
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

  List<Map<String, dynamic>> _filterProjects(
    List<Map<String, dynamic>> projects,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return projects;

    return projects.where((project) {
      final name = (project['name'] ?? '').toString().toLowerCase();
      final location = (project['location'] ?? '').toString().toLowerCase();
      return name.contains(query) || location.contains(query);
    }).toList();
  }

  Widget _buildDesktopHeader(
    BuildContext context,
    AppLocalizations l, {
    required int totalProjects,
    required int visibleProjects,
    required bool canManageProjects,
  }) {
    final queryIsActive = _searchQuery.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.desktopPaneDecoration(
        context,
        radius: 32,
        emphasized: true,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1080;
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project workspace',
                style: AppTheme.label.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'All projects in one desktop view',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Search projects quickly, open the right workspace faster, and keep unread activity visible without stretching a mobile layout across a desktop screen.',
                style: AppTheme.body.copyWith(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DesktopMetricPill(
                    icon: Icons.folder_copy_outlined,
                    label:
                        '$totalProjects ${totalProjects == 1 ? l.projectName : 'projects'}',
                  ),
                  _DesktopMetricPill(
                    icon: Icons.filter_alt_outlined,
                    label: queryIsActive
                        ? '$visibleProjects matching search'
                        : 'Showing all projects',
                  ),
                  _DesktopMetricPill(
                    icon: canManageProjects
                        ? Icons.admin_panel_settings_outlined
                        : Icons.visibility_outlined,
                    label: canManageProjects
                        ? 'Project admin access'
                        : 'Viewer access',
                  ),
                ],
              ),
            ],
          );

          final right = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DesktopSearchBox(
                controller: _searchController,
                hintText: 'Search by project or location',
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: _searchQuery.isEmpty
                    ? null
                    : () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(authProvider.notifier).refreshCurrentUser();
                      ref.invalidate(projectsProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l.refresh),
                  ),
                  if (canManageProjects) ...[
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _showAddProjectBottomSheet(context, ref),
                      icon: const Icon(Icons.add),
                      label: Text(l.createProject),
                    ),
                  ],
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 22), right],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 11, child: left),
              const SizedBox(width: 24),
              Expanded(flex: 7, child: right),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopEmptyState(
    BuildContext context, {
    required bool searching,
  }) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(28),
        decoration: AppTheme.desktopPaneDecoration(context, radius: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                searching
                    ? Icons.search_off_rounded
                    : Icons.folder_open_rounded,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              searching
                  ? 'No projects match your search'
                  : 'No projects found yet',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              searching
                  ? 'Try a different project name or location to surface the workspace you need.'
                  : 'Create the first workspace to give your team a cleaner desktop hub for tasks, attendance, and progress tracking.',
              style: AppTheme.body.copyWith(
                color: AppTheme.textSecondary,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final user = ref.watch(authProvider).currentUser;
    final canManageProjects = user != null && user.role.isAdmin;
    final canViewDashboard = user != null && user.role.canEdit;
    final l = AppLocalizations.of(context)!;
    final showPasswordActions = usesPasswordAuth;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: isWindowsDesktop
            ? AppTheme.surface.withValues(alpha: 0.76)
            : AppTheme.surface,
        centerTitle: false,
        toolbarHeight: 72,
        titleSpacing: isWindowsDesktop ? 24 : null,
        title: Image.asset('assets/images/rppl.png', height: 56),
        actions: [
          if (canViewDashboard)
            IconButton(
              icon: const Icon(Icons.dashboard_outlined),
              tooltip: 'Operations Dashboard',
              onPressed: () => context.push('/dashboard'),
            ),
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
              if (showPasswordActions)
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
      floatingActionButton: canManageProjects && !isWindowsDesktop
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
          final filteredProjects = _filterProjects(projects);

          if (isWindowsDesktop) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                child: Column(
                  children: [
                    _buildDesktopHeader(
                      context,
                      l,
                      totalProjects: projects.length,
                      visibleProjects: filteredProjects.length,
                      canManageProjects: canManageProjects,
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: filteredProjects.isEmpty
                          ? _buildDesktopEmptyState(
                              context,
                              searching: _searchQuery.trim().isNotEmpty,
                            )
                          : Scrollbar(
                              child: GridView.builder(
                                padding: const EdgeInsets.only(bottom: 12),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 380,
                                      mainAxisSpacing: 18,
                                      crossAxisSpacing: 18,
                                      mainAxisExtent: 220,
                                    ),
                                itemCount: filteredProjects.length,
                                itemBuilder: (context, index) => _DesktopProjectCard(
                                  project: filteredProjects[index],
                                  canManageProjects: canManageProjects,
                                  onOpen: () => context.push(
                                    '/projects/${filteredProjects[index]['id']}',
                                    extra: {
                                      'name': filteredProjects[index]['name'],
                                      'location':
                                          filteredProjects[index]['location'],
                                    },
                                  ),
                                  onDelete: () => _confirmDelete(
                                    context,
                                    ref,
                                    filteredProjects[index]['id'].toString(),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (projects.isEmpty) {
            return Center(child: Text(l.noProjectsFound));
          }
          Widget buildProjectCard(Map<String, dynamic> p) {
            return GestureDetector(
              onTap: () => context.push(
                '/projects/${p['id']}',
                extra: {'name': p['name'], 'location': p['location']},
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
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
                  Positioned(
                    bottom: -6,
                    right: -6,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final unreadCountAsync = ref.watch(
                          projectUnreadCountProvider(p['id']?.toString() ?? ''),
                        );
                        return unreadCountAsync.maybeWhen(
                          data: (count) {
                            if (count <= 0) return const SizedBox.shrink();
                            final label = count > 99 ? '99+' : count.toString();
                            return Container(
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          final bottomPadding = MediaQuery.of(context).padding.bottom;
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 110,
                  ),
                  itemCount: filteredProjects.length,
                  itemBuilder: (context, index) =>
                      buildProjectCard(filteredProjects[index]),
                );
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
                itemCount: filteredProjects.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    buildProjectCard(filteredProjects[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _DesktopMetricPill extends StatelessWidget {
  const _DesktopMetricPill({
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? Theme.of(context).colorScheme.primary;
    final resolvedTextColor = textColor ?? AppTheme.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor ??
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: resolvedIconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.body.copyWith(
              fontWeight: FontWeight.w600,
              color: resolvedTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSearchBox extends StatelessWidget {
  const _DesktopSearchBox({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTheme.body.copyWith(fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.68),
      ),
    );
  }
}

class _DesktopProjectCard extends ConsumerStatefulWidget {
  const _DesktopProjectCard({
    required this.project,
    required this.canManageProjects,
    required this.onOpen,
    required this.onDelete,
  });

  final Map<String, dynamic> project;
  final bool canManageProjects;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  ConsumerState<_DesktopProjectCard> createState() =>
      _DesktopProjectCardState();
}

class _DesktopProjectCardState extends ConsumerState<_DesktopProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final projectId = widget.project['id']?.toString() ?? '';
    final unreadCountAsync = ref.watch(projectUnreadCountProvider(projectId));
    final unreadCount = unreadCountAsync.asData?.value ?? 0;
    final name = (widget.project['name'] ?? 'Untitled').toString();
    final location = (widget.project['location'] ?? '').toString();
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: _isHovered ? 0.96 : 0.9),
              Color.lerp(
                Theme.of(context).colorScheme.surface,
                primary,
                _isHovered ? (isDark ? 0.1 : 0.05) : (isDark ? 0.06 : 0.03),
              )!,
            ],
          ),
          border: Border.all(
            color: _isHovered
                ? primary.withValues(alpha: 0.18)
                : AppTheme.textSecondary.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.1),
              blurRadius: _isHovered ? 28 : 18,
              offset: Offset(0, _isHovered ? 16 : 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: widget.onOpen,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (location.isNotEmpty)
                              _DesktopMetricPill(
                                icon: Icons.location_on_outlined,
                                label: location,
                              ),
                            _DesktopUnreadPill(unreadCountAsync: unreadCountAsync),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (unreadCount > 0) ...[
                            _DesktopUnreadBadge(count: unreadCount),
                            const SizedBox(width: 8),
                          ],
                          if (widget.canManageProjects)
                            IconButton(
                              tooltip: 'Delete project',
                              onPressed: widget.onDelete,
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    location.isEmpty ? 'Location not added yet' : location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: unreadCountAsync.when(
                          data: (count) {
                            final label = count <= 0
                                ? 'All caught up'
                                : count == 1
                                ? '1 unread update'
                                : '$count unread updates';
                            return Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body.copyWith(
                                color: count > 0
                                    ? const Color(0xFFD94B4B)
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                          loading: () => Text(
                            'Checking updates…',
                            style: AppTheme.body.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          error: (_, _) => Text(
                            'Open project',
                            style: AppTheme.body.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Open project',
                        style: AppTheme.body.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 18,
                        color: primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopUnreadPill extends StatelessWidget {
  const _DesktopUnreadPill({required this.unreadCountAsync});

  final AsyncValue<int> unreadCountAsync;

  @override
  Widget build(BuildContext context) {
    return unreadCountAsync.when(
      data: (count) {
        if (count <= 0) {
          return _DesktopMetricPill(
            icon: Icons.check_circle_outline_rounded,
            label: 'All caught up',
          );
        }

        return _DesktopMetricPill(
          icon: Icons.notifications_active_outlined,
          label: count > 99 ? '99+ unread' : '$count unread',
          iconColor: const Color(0xFFD94B4B),
          textColor: const Color(0xFFD94B4B),
          backgroundColor: const Color(0xFFD94B4B).withAlpha(22),
          borderColor: const Color(0xFFD94B4B).withAlpha(56),
        );
      },
      loading: () => _DesktopMetricPill(
        icon: Icons.sync_rounded,
        label: 'Checking updates',
      ),
      error: (_, _) => _DesktopMetricPill(
        icon: Icons.workspaces_outline,
        label: 'Project ready',
      ),
    );
  }
}

class _DesktopUnreadBadge extends StatelessWidget {
  const _DesktopUnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      constraints: const BoxConstraints(minWidth: 34, minHeight: 30),
      decoration: BoxDecoration(
        color: const Color(0xFFD94B4B),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
