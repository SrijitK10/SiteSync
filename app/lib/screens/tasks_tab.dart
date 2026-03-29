// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../services/api_client.dart';

class TasksTab extends ConsumerStatefulWidget {
  final String projectId;
  const TasksTab({super.key, required this.projectId});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final res = await apiClient.get('/tasks?projectId=${widget.projectId}');
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

  Future<void> _fetchAndExportExcel(String range, {String? startDate, String? endDate}) async {
    setState(() => _isExporting = true);
    try {
      String url = '/tasks?projectId=${widget.projectId}&range=$range';
      if (range == 'custom' && startDate != null && endDate != null) {
        url += '&startDate=$startDate&endDate=$endDate';
      }
      final res = await apiClient.get(url);
      final List<dynamic> remoteRecords = res.data;

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Tasks'];
      excel.setDefaultSheet('Tasks');

      sheetObject.appendRow([
        TextCellValue('Task Title'),
        TextCellValue('Notes / Description'),
        TextCellValue('Status'),
        TextCellValue('Creation Date'),
        TextCellValue('Completion Date'),
      ]);

      for (var r in remoteRecords) {
        sheetObject.appendRow([
          TextCellValue(r['title'] ?? 'Unknown'),
          TextCellValue(r['description'] ?? ''),
          TextCellValue(r['status'] ?? 'todo'),
          TextCellValue(r['created_at'] ?? ''),
          TextCellValue(r['completed_at'] ?? 'Pending'),
        ]);
      }

      final directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/SiteSync_Tasks_${range}_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final List<int>? fileBytes = excel.save();
      
      if (fileBytes != null) {
        File dataFile = File(filePath);
        await dataFile.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(filePath)], text: 'SiteSync $range Tasks Export');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export extraction failed: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _showCustomDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final start = picked.start.toIso8601String().split('T')[0];
      final end = picked.end.toIso8601String().split('T')[0];
      _fetchAndExportExcel('custom', startDate: start, endDate: end);
    }
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Download Task Tracking Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.today, color: AppTheme.accent),
                title: const Text('Export Daily Created/Completed'),
                onTap: () { Navigator.pop(context); _fetchAndExportExcel('daily'); },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: AppTheme.accent),
                title: const Text('Export Weekly Summary'),
                onTap: () { Navigator.pop(context); _fetchAndExportExcel('weekly'); },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: AppTheme.accent),
                title: const Text('Export Monthly Complete Tracker'),
                onTap: () { Navigator.pop(context); _fetchAndExportExcel('monthly'); },
              ),
              ListTile(
                leading: const Icon(Icons.tune, color: AppTheme.primary),
                title: const Text('Export Custom Date Range'),
                onTap: () { Navigator.pop(context); _showCustomDateRangePicker(); },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
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
                  Text('Create New Task', style: AppTheme.heading),
                  const SizedBox(height: 16),
                  AppTextField(label: 'TITLE', hint: 'E.g. Pour Foundation', controller: titleController),
                  const SizedBox(height: 16),
                  AppTextField(label: 'NOTES', hint: 'Add required materials, warnings, or descriptions...', controller: notesController),
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
                              'title': titleController.text.trim(),
                              'description': notesController.text.trim()
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
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _showAddTaskSheet,
        child: const Icon(Icons.add, color: AppTheme.surface),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _isExporting 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : AppButton(
                  text: '⬇️ Download Task Reports',
                  onPressed: () => _showExportOptions(context),
                ),
            const SizedBox(height: 16),
            Expanded(
              child: _tasks.isEmpty
                ? const Center(child: Text('No tasks created yet.'))
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
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                (t['description'] == null || t['description'].toString().trim().isEmpty)
                                    ? 'No notes provided.'
                                    : t['description'],
                                style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
