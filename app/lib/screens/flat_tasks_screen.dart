// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../services/api_client.dart';
import '../state/auth_provider.dart';

class FlatTasksScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String flatId;
  final String flatNumber;

  const FlatTasksScreen({
    super.key,
    required this.projectId,
    required this.flatId,
    required this.flatNumber,
  });

  @override
  ConsumerState<FlatTasksScreen> createState() => _FlatTasksScreenState();
}

class _FlatTasksScreenState extends ConsumerState<FlatTasksScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final res = await apiClient.get(
        '/tasks?projectId=${widget.projectId}&flatId=${widget.flatId}',
      );
      if (mounted) {
        setState(() {
          _tasks = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load tasks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTaskStatus(String id, String currentStatus) async {
    String newStatus = currentStatus == 'completed' ? 'todo' : 'completed';
    try {
      await apiClient.patch('/tasks/$id', data: {'status': newStatus});
      _fetchTasks();
    } catch (e) {
      debugPrint('Error toggling status: $e');
    }
  }

  Widget _buildNotesField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOTES', style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: null,
          minLines: 3,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: AppTheme.body,
          decoration: InputDecoration(
            hintText: 'Add required materials, warnings, or descriptions...\nUse Enter to add a new line.',
            hintStyle: AppTheme.body.copyWith(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.accent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesBullets(String? description) {
    if (description == null || description.trim().isEmpty) {
      return Text('No notes provided.', style: AppTheme.body.copyWith(color: AppTheme.textSecondary));
    }
    final lines = description.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return Text('No notes provided.', style: AppTheme.body.copyWith(color: AppTheme.textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: AppTheme.body.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            Expanded(child: Text(line.trim(), style: AppTheme.body.copyWith(color: AppTheme.textSecondary))),
          ],
        ),
      )).toList(),
    );
  }

  void _showEditNotesSheet(Map<String, dynamic> task) {
    final notesController = TextEditingController(text: task['description'] ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setStateLocal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Notes', style: AppTheme.heading),
                  const SizedBox(height: 16),
                  _buildNotesField(notesController),
                  const SizedBox(height: 32),
                  isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : AppButton(
                        text: 'Save Notes',
                        onPressed: () async {
                          setStateLocal(() => isSubmitting = true);
                          try {
                            await apiClient.patch('/tasks/${task['id']}', data: {
                              'description': notesController.text.trim(),
                            });
                            _fetchTasks();
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint('Error updating notes: $e');
                            if (context.mounted) setStateLocal(() => isSubmitting = false);
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

  Future<void> _deleteTask(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await apiClient.delete('/tasks/$id');
      _fetchTasks();
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setStateLocal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('New Task for Flat ${widget.flatNumber}', style: AppTheme.heading),
                  const SizedBox(height: 16),
                  AppTextField(label: 'TITLE', hint: 'E.g. Pour Foundation', controller: titleController),
                  const SizedBox(height: 16),
                  _buildNotesField(notesController),
                  const SizedBox(height: 32),
                  isSubmitting
                    ? const CircularProgressIndicator()
                    : AppButton(
                        text: 'Save Task',
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty) return;
                          setStateLocal(() => isSubmitting = true);
                          try {
                            await apiClient.post('/tasks', data: {
                              'projectId': widget.projectId,
                              'flatId': widget.flatId,
                              'title': titleController.text.trim(),
                              'description': notesController.text.trim(),
                            });
                            _fetchTasks();
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint('Error creating task: $e');
                            if (context.mounted) setStateLocal(() => isSubmitting = false);
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
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).currentUser;
    final canEdit = currentUser?.role.canEdit == true;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Flat ${widget.flatNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add, color: AppTheme.surface),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _tasks.isEmpty
                  ? const Center(child: Text('No tasks created for this flat yet.'))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final t = _tasks[index];
                        final bool isDone = t['status'] == 'completed';
                        return Card(
                          color: AppTheme.surface,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: Checkbox(
                              value: isDone,
                              activeColor: AppTheme.success,
                              onChanged: (val) => _toggleTaskStatus(t['id'], t['status']),
                            ),
                            title: Text(
                              t['title'] ?? 'Untitled',
                              style: AppTheme.body.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text(isDone ? 'Finished: ${t['completed_at']}' : 'Added: ${t['created_at']}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildNotesBullets(t['description']),
                                    if (canEdit) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _showEditNotesSheet(Map<String, dynamic>.from(t)),
                                            icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
                                            label: const Text('Edit Notes', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          TextButton.icon(
                                            onPressed: () => _deleteTask(t['id']),
                                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                            label: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
