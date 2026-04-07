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
import '../state/auth_provider.dart';
import 'flat_tasks_screen.dart';

class TasksTab extends ConsumerStatefulWidget {
  final String projectId;
  const TasksTab({super.key, required this.projectId});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  List<dynamic> _flats = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _fetchFlats();
  }

  Future<void> _fetchFlats() async {
    try {
      final res = await apiClient.get('/flats?projectId=${widget.projectId}');
      if (mounted) {
        setState(() {
          _flats = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load flats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createFlat(String flatNumber) async {
    try {
      await apiClient.post('/flats', data: {
        'projectId': widget.projectId,
        'flat_number': flatNumber,
      });
      _fetchFlats();
    } catch (e) {
      debugPrint('Error creating flat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add flat: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleFlatCompleted(Map<String, dynamic> flat) async {
    final bool current = flat['is_completed'] == true;
    try {
      await apiClient.patch('/flats/${flat['id']}', data: {'is_completed': !current});
      _fetchFlats();
    } catch (e) {
      debugPrint('Error toggling flat: $e');
    }
  }

  Future<void> _deleteFlat(Map<String, dynamic> flat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Flat ${flat['flat_number']}'),
        content: const Text(
          'This will remove the flat. Tasks under this flat will be unlinked but not deleted. Continue?',
        ),
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
      await apiClient.delete('/flats/${flat['id']}');
      _fetchFlats();
    } catch (e) {
      debugPrint('Error deleting flat: $e');
    }
  }

  void _showAddFlatSheet() {
    final controller = TextEditingController();
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
                  Text('Add Flat', style: AppTheme.heading),
                  const SizedBox(height: 16),
                  AppTextField(label: 'FLAT NUMBER', hint: 'E.g. 101', controller: controller),
                  const SizedBox(height: 32),
                  isSubmitting
                      ? const CircularProgressIndicator()
                      : AppButton(
                          text: 'Add Flat',
                          onPressed: () async {
                            if (controller.text.trim().isEmpty) return;
                            setStateLocal(() => isSubmitting = true);
                            await _createFlat(controller.text.trim());
                            if (context.mounted) Navigator.pop(context);
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
        TextCellValue('Flat'),
        TextCellValue('Task Title'),
        TextCellValue('Notes / Description'),
        TextCellValue('Status'),
        TextCellValue('Creation Date'),
        TextCellValue('Completion Date'),
      ]);

      for (var r in remoteRecords) {
        sheetObject.appendRow([
          TextCellValue(r['flat']?['flat_number']?.toString() ?? '-'),
          TextCellValue(r['title'] ?? 'Unknown'),
          TextCellValue(r['description'] ?? ''),
          TextCellValue(r['status'] ?? 'todo'),
          TextCellValue(r['created_at'] ?? ''),
          TextCellValue(r['completed_at'] ?? 'Pending'),
        ]);
      }

      final directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/Rupayan_Tasks_${range}_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final List<int>? fileBytes = excel.save();

      if (fileBytes != null) {
        File dataFile = File(filePath);
        await dataFile.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(filePath)], text: 'Rupayan $range Tasks Export');
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

  void _openFlat(Map<String, dynamic> flat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlatTasksScreen(
          projectId: widget.projectId,
          flatId: flat['id'].toString(),
          flatNumber: flat['flat_number'].toString(),
        ),
      ),
    ).then((_) => _fetchFlats());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final currentUser = ref.watch(authProvider).currentUser;
    final isViewer = currentUser?.role.value == 'viewer';
    final canEdit = currentUser?.role.canEdit == true;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              onPressed: _showAddFlatSheet,
              icon: const Icon(Icons.add, color: AppTheme.surface),
              label: const Text('Add Flat', style: TextStyle(color: AppTheme.surface)),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isViewer) ...[
              if (_isExporting)
                const Center(child: Padding(padding: EdgeInsets.only(bottom: 16), child: CircularProgressIndicator(color: AppTheme.accent)))
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showExportOptions(context),
                    icon: const Icon(Icons.download, size: 18, color: AppTheme.primary),
                    label: const Text('Download Reports', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: _flats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.apartment, size: 48, color: AppTheme.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            canEdit
                                ? 'No flats yet.\nTap "Add Flat" to get started.'
                                : 'No flats have been added yet.',
                            textAlign: TextAlign.center,
                            style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _flats.length,
                      itemBuilder: (context, index) {
                        final flat = Map<String, dynamic>.from(_flats[index]);
                        final bool isCompleted = flat['is_completed'] == true;
                        return _FlatCard(
                          flat: flat,
                          isCompleted: isCompleted,
                          canEdit: canEdit,
                          onTap: () => _openFlat(flat),
                          onToggleCompleted: () => _toggleFlatCompleted(flat),
                          onDelete: () => _deleteFlat(flat),
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

class _FlatCard extends StatelessWidget {
  final Map<String, dynamic> flat;
  final bool isCompleted;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onToggleCompleted;
  final VoidCallback onDelete;

  const _FlatCard({
    required this.flat,
    required this.isCompleted,
    required this.canEdit,
    required this.onTap,
    required this.onToggleCompleted,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCompleted ? AppTheme.success.withAlpha(30) : AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.apartment,
                    color: isCompleted ? AppTheme.success : AppTheme.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    flat['flat_number']?.toString() ?? '?',
                    style: AppTheme.heading.copyWith(
                      fontSize: 20,
                      color: isCompleted ? AppTheme.success : AppTheme.textPrimary,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationThickness: 2,
                    ),
                  ),
                ],
              ),
            ),
            if (canEdit)
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textSecondary),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'toggle') onToggleCompleted();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isCompleted ? Icons.undo : Icons.check,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(isCompleted ? 'Unmark Done' : 'Mark Done'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
