import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../state/projects_provider.dart';

import '../services/api_client.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Live Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(projectsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showAddProjectBottomSheet(context, ref),
        child: const Icon(Icons.add, color: AppTheme.surface),
      ),
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
                onTap: () => context.push('/projects/${p['id']}'),
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
                          Row(
                            children: [
                              Chip(
                                label: Text((p['status'] ?? 'Draft').toString().toUpperCase(), style: AppTheme.label.copyWith(fontSize: 10)),
                                backgroundColor: AppTheme.accent.withAlpha(50),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _confirmDelete(context, ref, p['id'].toString());
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Project', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
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
                      const SizedBox(height: 16),
                      // Mock progress natively for backend missing schema elements
                      LinearProgressIndicator(
                        value: (p['progress'] != null) ? p['progress'] as double : 0.5,
                        backgroundColor: AppTheme.background,
                        color: AppTheme.success,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
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
