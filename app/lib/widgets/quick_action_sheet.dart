import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../state/projects_provider.dart';
import '../services/api_client.dart';
import '../screens/attendance_screen.dart';

class QuickActionSheet extends ConsumerStatefulWidget {
  const QuickActionSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const QuickActionSheet(),
    );
  }

  @override
  ConsumerState<QuickActionSheet> createState() => _QuickActionSheetState();
}

class _QuickActionSheetState extends ConsumerState<QuickActionSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text('Quick Actions', style: AppTheme.heading.copyWith(fontSize: 20)),
          const SizedBox(height: 24),
          _buildActionCard(
            context: context,
            icon: Icons.assignment_add,
            title: 'Add / Update Task',
            subtitle: 'Quickly log a task for any property',
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              GlobalTaskEntryModal.show(context);
            },
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            icon: Icons.co_present,
            title: 'Mark Attendance',
            subtitle: 'Record attendance for a property',
            color: Colors.green,
            onTap: () {
              Navigator.pop(context);
              _showProjectSelectionForAttendance(context, ref);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.label.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProjectSelectionForAttendance(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ProjectSelectionSheet(actionType: 'attendance'),
    );
  }
}

class ProjectSelectionSheet extends ConsumerWidget {
  final String actionType;
  const ProjectSelectionSheet({super.key, required this.actionType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Property',
            style: AppTheme.heading.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return const Center(child: Text('No projects found.'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return ListTile(
                      leading: const Icon(Icons.apartment),
                      title: Text(project['name'] ?? 'Unknown'),
                      subtitle: Text(project['location'] ?? ''),
                      onTap: () {
                        Navigator.pop(context);
                        if (actionType == 'attendance') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  title: Text(
                                    'Attendance - ${project['name']}',
                                  ),
                                  backgroundColor: AppTheme.surface,
                                ),
                                body: AttendanceScreen(
                                  projectId: project['id'],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class GlobalTaskEntryModal extends ConsumerStatefulWidget {
  const GlobalTaskEntryModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const GlobalTaskEntryModal(),
    );
  }

  @override
  ConsumerState<GlobalTaskEntryModal> createState() =>
      _GlobalTaskEntryModalState();
}

class _GlobalTaskEntryModalState extends ConsumerState<GlobalTaskEntryModal> {
  String? _selectedProjectId;
  String? _selectedFlatId;
  List<dynamic> _flats = [];
  bool _isLoadingFlats = false;
  final TextEditingController _taskController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _fetchFlats(String projectId) async {
    setState(() {
      _isLoadingFlats = true;
      _selectedFlatId = null;
      _flats = [];
    });
    try {
      final res = await apiClient.get('/flats?projectId=$projectId');
      if (mounted) {
        setState(() {
          _flats = res.data is List ? List<dynamic>.from(res.data) : [];
        });
      }
    } catch (e) {
      debugPrint('Failed to load flats: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFlats = false);
    }
  }

  Future<void> _submitTask() async {
    if (_selectedProjectId == null ||
        _selectedFlatId == null ||
        _taskController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await apiClient.post(
        '/tasks',
        data: {
          'projectId': _selectedProjectId,
          'flatId': _selectedFlatId,
          'title': _taskController.text.trim(),
          'status': 'todo',
        },
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error adding task: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add task: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add New Task',
              style: AppTheme.heading.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Project Selection
            Text('Property', style: AppTheme.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: projectsAsync.when(
                data: (projects) {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedProjectId,
                      hint: const Text('Select a Property'),
                      isExpanded: true,
                      items: projects.map((p) {
                        return DropdownMenuItem<String>(
                          value: p['id'].toString(),
                          child: Text(p['name'].toString()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null && val != _selectedProjectId) {
                          setState(() {
                            _selectedProjectId = val;
                          });
                          _fetchFlats(val);
                        }
                      },
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 16),

            // Flat Selection
            Text('Flat / Unit', style: AppTheme.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoadingFlats
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFlatId,
                        hint: Text(
                          _selectedProjectId == null
                              ? 'Select Property first'
                              : 'Select a Flat',
                        ),
                        isExpanded: true,
                        items: _flats.map((f) {
                          return DropdownMenuItem<String>(
                            value: f['id'].toString(),
                            child: Text(f['flat_number'].toString()),
                          );
                        }).toList(),
                        onChanged: _selectedProjectId == null
                            ? null
                            : (val) {
                                setState(() {
                                  _selectedFlatId = val;
                                });
                              },
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Task Description
            Text('Task Description', style: AppTheme.label),
            const SizedBox(height: 8),
            TextField(
              controller: _taskController,
              decoration: InputDecoration(
                hintText: 'E.g. Fix plumbing in bathroom',
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed:
                  _isSubmitting ||
                      _selectedProjectId == null ||
                      _selectedFlatId == null ||
                      _taskController.text.trim().isEmpty
                  ? null
                  : _submitTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Add Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
