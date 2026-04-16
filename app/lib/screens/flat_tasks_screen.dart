// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../services/api_client.dart';
import '../state/auth_provider.dart';
import '../state/unread_tracker_provider.dart';
import '../l10n/app_localizations.dart';

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
      final tasks = List<dynamic>.from(res.data as List<dynamic>);
      final userId = ref.read(authProvider).currentUser?.id;
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
      if (userId != null) {
        await ref
            .read(unreadTrackerProvider.notifier)
            .markFlatVisited(
              userId: userId,
              projectId: widget.projectId,
              flatId: widget.flatId,
              tasks: tasks,
            );
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

  String _creatorName(Map<String, dynamic> task, AppLocalizations l) {
    final createdBy = task['createdBy'];
    if (createdBy is Map &&
        createdBy['name']?.toString().trim().isNotEmpty == true) {
      return createdBy['name'].toString().trim();
    }
    return l.unknownUser;
  }

  Future<List<Map<String, dynamic>>> _fetchOtherFlatsForImport() async {
    final res = await apiClient.get('/flats?projectId=${widget.projectId}');
    return (res.data as List<dynamic>)
        .map((flat) => Map<String, dynamic>.from(flat as Map))
        .where((flat) => flat['id']?.toString() != widget.flatId)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchTasksForImport(
    String sourceFlatId,
  ) async {
    final res = await apiClient.get(
      '/tasks?projectId=${widget.projectId}&flatId=$sourceFlatId',
    );
    return (res.data as List<dynamic>)
        .map((task) => Map<String, dynamic>.from(task as Map))
        .toList();
  }

  Future<void> _showImportTasksSheet() async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    List<Map<String, dynamic>> otherFlats;
    try {
      otherFlats = await _fetchOtherFlatsForImport();
    } catch (e) {
      debugPrint('Failed to load flats for import: $e');
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l.connectionError)));
      }
      return;
    }

    if (!mounted) return;

    if (otherFlats.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.noOtherFlats)));
      return;
    }

    String selectedSourceFlatId = otherFlats.first['id'].toString();
    List<Map<String, dynamic>> sourceTasks;
    try {
      sourceTasks = await _fetchTasksForImport(selectedSourceFlatId);
    } catch (e) {
      debugPrint('Failed to load source flat tasks: $e');
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l.connectionError)));
      }
      return;
    }

    if (!mounted) return;

    final selectedTaskIds = <String>{};
    bool isSubmitting = false;
    bool isLoadingSourceTasks = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      builder: (bottomSheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: StatefulBuilder(
            builder: (context, setStateLocal) {
              Future<void> loadSourceTasks(String flatId) async {
                setStateLocal(() {
                  selectedSourceFlatId = flatId;
                  isLoadingSourceTasks = true;
                  selectedTaskIds.clear();
                });

                try {
                  final tasks = await _fetchTasksForImport(flatId);
                  if (!mounted) return;
                  setStateLocal(() {
                    sourceTasks = tasks;
                    isLoadingSourceTasks = false;
                  });
                } catch (e) {
                  debugPrint('Failed to load import tasks: $e');
                  if (!mounted) return;
                  setStateLocal(() {
                    sourceTasks = [];
                    isLoadingSourceTasks = false;
                  });
                  messenger.showSnackBar(
                    SnackBar(content: Text(l.connectionError)),
                  );
                }
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.importTasks, style: AppTheme.heading),
                    const SizedBox(height: 8),
                    Text(
                      l.importTasksDescription,
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l.importTasksInfo,
                        style: AppTheme.body.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(l.selectSourceFlat, style: AppTheme.label),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedSourceFlatId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppTheme.accent,
                            width: 2,
                          ),
                        ),
                      ),
                      items: otherFlats
                          .map(
                            (flat) => DropdownMenuItem<String>(
                              value: flat['id'].toString(),
                              child: Text(
                                '${l.flat} ${flat['flat_number']?.toString() ?? ''}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null || value == selectedSourceFlatId) {
                          return;
                        }
                        loadSourceTasks(value);
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(l.selectTasksToImport, style: AppTheme.label),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: isLoadingSourceTasks
                            ? const Center(child: CircularProgressIndicator())
                            : sourceTasks.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    l.noTasksToImport,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.body.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: sourceTasks.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final task = sourceTasks[index];
                                  final taskId = task['id'].toString();
                                  final isSelected = selectedTaskIds.contains(
                                    taskId,
                                  );
                                  return CheckboxListTile(
                                    value: isSelected,
                                    activeColor: AppTheme.primary,
                                    title: Text(
                                      task['title']
                                                  ?.toString()
                                                  .trim()
                                                  .isNotEmpty ==
                                              true
                                          ? task['title'].toString()
                                          : l.untitled,
                                      style: AppTheme.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      l.importTasksInfo,
                                      style: AppTheme.body.copyWith(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: (value) {
                                      setStateLocal(() {
                                        if (value == true) {
                                          selectedTaskIds.add(taskId);
                                        } else {
                                          selectedTaskIds.remove(taskId);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: l.importSelected,
                      isLoading: isSubmitting,
                      onPressed: () async {
                        if (selectedTaskIds.isEmpty) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(l.selectAtLeastOneTaskToImport),
                            ),
                          );
                          return;
                        }

                        setStateLocal(() => isSubmitting = true);
                        try {
                          await apiClient.post(
                            '/tasks/copy',
                            data: {
                              'taskIds': selectedTaskIds.toList(),
                              'targetFlatId': widget.flatId,
                              'projectId': widget.projectId,
                            },
                          );
                          await _fetchTasks();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          messenger.showSnackBar(
                            SnackBar(content: Text(l.tasksImportedSuccess)),
                          );
                        } catch (e) {
                          debugPrint('Error importing tasks: $e');
                          if (context.mounted) {
                            setStateLocal(() => isSubmitting = false);
                          }
                          messenger.showSnackBar(
                            SnackBar(content: Text(l.connectionError)),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotesField(TextEditingController controller) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.notesLabel, style: AppTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: null,
          minLines: 3,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          style: AppTheme.body,
          decoration: InputDecoration(
            hintText: l.notesHint,
            hintStyle: AppTheme.body.copyWith(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.accent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesBullets(String? description) {
    final l = AppLocalizations.of(context)!;
    if (description == null || description.trim().isEmpty) {
      return Text(
        l.noNotesProvided,
        style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
      );
    }
    final lines = description
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return Text(
        l.noNotesProvided,
        style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTheme.body.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line.trim(),
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  void _showEditNotesSheet(Map<String, dynamic> task) {
    final notesController = TextEditingController(
      text: task['description'] ?? '',
    );
    bool isSubmitting = false;
    final l = AppLocalizations.of(context)!;

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
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.editNotes, style: AppTheme.heading),
                  const SizedBox(height: 16),
                  _buildNotesField(notesController),
                  const SizedBox(height: 32),
                  isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : AppButton(
                          text: l.saveNotes,
                          onPressed: () async {
                            setStateLocal(() => isSubmitting = true);
                            try {
                              await apiClient.patch(
                                '/tasks/${task['id']}',
                                data: {
                                  'description': notesController.text.trim(),
                                },
                              );
                              _fetchTasks();
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              debugPrint('Error updating notes: $e');
                              if (context.mounted) {
                                setStateLocal(() => isSubmitting = false);
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

  Future<void> _deleteTask(String id) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteTask),
        content: Text(l.deleteTaskConfirm),
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
    final l = AppLocalizations.of(context)!;

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
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.newTaskForFlat(widget.flatNumber),
                    style: AppTheme.heading,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: l.titleLabel,
                    hint: l.titleHint,
                    controller: titleController,
                  ),
                  const SizedBox(height: 16),
                  _buildNotesField(notesController),
                  const SizedBox(height: 32),
                  isSubmitting
                      ? const CircularProgressIndicator()
                      : AppButton(
                          text: l.saveTask,
                          onPressed: () async {
                            if (titleController.text.trim().isEmpty) return;
                            setStateLocal(() => isSubmitting = true);
                            try {
                              await apiClient.post(
                                '/tasks',
                                data: {
                                  'projectId': widget.projectId,
                                  'flatId': widget.flatId,
                                  'title': titleController.text.trim(),
                                  'description': notesController.text.trim(),
                                },
                              );
                              _fetchTasks();
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              debugPrint('Error creating task: $e');
                              if (context.mounted) {
                                setStateLocal(() => isSubmitting = false);
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).currentUser;
    final canEdit = currentUser?.role.canEdit ?? false;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          '${l.flat} ${widget.flatNumber}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: canEdit
            ? [
                IconButton(
                  tooltip: l.importTasks,
                  onPressed: _showImportTasksSheet,
                  icon: const Icon(Icons.file_download_outlined),
                ),
              ]
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _showAddTaskSheet,
        child: Icon(Icons.add, color: AppTheme.surface),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _tasks.isEmpty
                  ? Center(child: Text(l.noTasksYet))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final t = _tasks[index];
                        final bool isDone = t['status'] == 'completed';
                        final creatorName = _creatorName(
                          Map<String, dynamic>.from(t),
                          l,
                        );
                        return Card(
                          color: AppTheme.surface,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: Checkbox(
                              value: isDone,
                              activeColor: AppTheme.success,
                              onChanged: (val) =>
                                  _toggleTaskStatus(t['id'], t['status']),
                            ),
                            title: Text(
                              t['title'] ?? l.untitled,
                              style: AppTheme.body.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDone
                                      ? l.finished(t['completed_at'] ?? '')
                                      : l.added(t['created_at'] ?? ''),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l.addedBy(creatorName),
                                  style: AppTheme.body.copyWith(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.addedBy(creatorName),
                                      style: AppTheme.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildNotesBullets(t['description']),
                                    if (canEdit) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () =>
                                                _showEditNotesSheet(
                                                  Map<String, dynamic>.from(t),
                                                ),
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              size: 16,
                                              color: AppTheme.primary,
                                            ),
                                            label: Text(
                                              l.editNotes,
                                              style: TextStyle(
                                                color: AppTheme.primary,
                                                fontSize: 13,
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          TextButton.icon(
                                            onPressed: () =>
                                                _deleteTask(t['id']),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            label: Text(
                                              l.delete,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 13,
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
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
