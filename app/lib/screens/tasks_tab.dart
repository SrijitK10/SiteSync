// ignore_for_file: deprecated_member_use
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart';
import '../services/file_export.dart';
import '../services/platform_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../services/api_client.dart';
import '../state/auth_provider.dart';
import '../state/unread_tracker_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/desktop_section_shell.dart';
import '../widgets/unread_badge.dart';
import 'flat_tasks_screen.dart';

class TasksTab extends ConsumerStatefulWidget {
  final String projectId;
  const TasksTab({super.key, required this.projectId});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  List<dynamic> _flats = [];
  List<dynamic> _projectTasks = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    try {
      final responses = await Future.wait([
        apiClient.get('/flats?projectId=${widget.projectId}'),
        apiClient.get('/tasks?projectId=${widget.projectId}'),
      ]);

      final flatsResponse = responses[0];
      final tasksResponse = responses[1];
      if (mounted) {
        setState(() {
          _flats = flatsResponse.data is List
              ? List<dynamic>.from(flatsResponse.data)
              : [];
          _projectTasks = tasksResponse.data is List
              ? List<dynamic>.from(tasksResponse.data)
              : [];
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
      await apiClient.post(
        '/flats',
        data: {'projectId': widget.projectId, 'flat_number': flatNumber},
      );
      _refreshData();
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
      await apiClient.patch(
        '/flats/${flat['id']}',
        data: {'is_completed': !current},
      );
      _refreshData();
    } catch (e) {
      debugPrint('Error toggling flat: $e');
    }
  }

  Future<void> _deleteFlat(Map<String, dynamic> flat) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteFlat(flat['flat_number'].toString())),
        content: Text(l.deleteFlatWarning),
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
      await apiClient.delete('/flats/${flat['id']}');
      _refreshData();
    } catch (e) {
      debugPrint('Error deleting flat: $e');
    }
  }

  void _showAddFlatSheet() {
    final controller = TextEditingController();
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
                  Text(l.addFlat, style: AppTheme.heading),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: l.flatNumber,
                    hint: l.flatNumberHint,
                    controller: controller,
                  ),
                  const SizedBox(height: 32),
                  isSubmitting
                      ? const CircularProgressIndicator()
                      : AppButton(
                          text: l.addFlat,
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

  Future<void> _fetchAndExportExcel(
    String range, {
    String? startDate,
    String? endDate,
  }) async {
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
        TextCellValue('Added By'),
        TextCellValue('Completion Date'),
      ]);

      for (var r in remoteRecords) {
        sheetObject.appendRow([
          TextCellValue(r['flat']?['flat_number']?.toString() ?? '-'),
          TextCellValue(r['title'] ?? 'Unknown'),
          TextCellValue(r['description'] ?? ''),
          TextCellValue(r['status'] ?? 'todo'),
          TextCellValue(r['created_at'] ?? ''),
          TextCellValue(r['createdBy']?['name']?.toString() ?? '-'),
          TextCellValue(r['completed_at'] ?? 'Pending'),
        ]);
      }

      final List<int>? fileBytes = excel.save();

      if (fileBytes != null) {
        final fileName =
            'Rupayan_Tasks_${range}_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        await exportFile(
          bytes: Uint8List.fromList(fileBytes),
          fileName: fileName,
          shareText: 'Rupayan $range Tasks Export',
        );
      }
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l.exportFailed}: $e')));
      }
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
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.primary),
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
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l.downloadTaskReports,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.today, color: AppTheme.accent),
                title: Text(l.exportDaily),
                onTap: () {
                  Navigator.pop(context);
                  _fetchAndExportExcel('daily');
                },
              ),
              ListTile(
                leading: Icon(Icons.date_range, color: AppTheme.accent),
                title: Text(l.exportWeekly),
                onTap: () {
                  Navigator.pop(context);
                  _fetchAndExportExcel('weekly');
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_month, color: AppTheme.accent),
                title: Text(l.exportMonthly),
                onTap: () {
                  Navigator.pop(context);
                  _fetchAndExportExcel('monthly');
                },
              ),
              ListTile(
                leading: Icon(Icons.tune, color: AppTheme.primary),
                title: Text(l.exportCustom),
                onTap: () {
                  Navigator.pop(context);
                  _showCustomDateRangePicker();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _tasksForFlat(String flatId) {
    return _projectTasks
        .whereType<Map>()
        .map((task) => Map<String, dynamic>.from(task))
        .where((task) => task['flat']?['id']?.toString() == flatId)
        .toList();
  }

  void _openFlat(Map<String, dynamic> flat) {
    final currentUser = ref.read(authProvider).currentUser;
    final flatId = flat['id']?.toString();
    if (currentUser != null && flatId != null && flatId.isNotEmpty) {
      ref
          .read(unreadTrackerProvider.notifier)
          .markFlatVisited(
            userId: currentUser.id,
            projectId: widget.projectId,
            flatId: flatId,
            tasks: _tasksForFlat(flatId),
          );
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => FlatTasksScreen(
              projectId: widget.projectId,
              flatId: flatId ?? '',
              flatNumber: flat['flat_number'].toString(),
            ),
          ),
        )
        .then((_) => _refreshData());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final currentUser = ref.watch(authProvider).currentUser;
    ref.watch(unreadTrackerProvider);
    final isViewer = currentUser == null || currentUser.role.value == 'viewer';
    final canEdit = currentUser?.role.canEdit ?? false;
    final l = AppLocalizations.of(context)!;
    final unreadTracker = ref.read(unreadTrackerProvider.notifier);
    final isWindows = isWindowsDesktop;
    final completedFlats = _flats
        .where((flat) => flat['is_completed'] == true)
        .length;
    final pendingFlats = _flats.length - completedFlats;

    final tasksByFlatId = <String, List<Map<String, dynamic>>>{};
    for (final rawTask in _projectTasks) {
      if (rawTask is! Map) continue;
      final task = Map<String, dynamic>.from(rawTask);
      final flatId = task['flat']?['id']?.toString();
      if (flatId == null || flatId.isEmpty) continue;
      tasksByFlatId.putIfAbsent(flatId, () => []).add(task);
    }

    if (isWindows) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopSectionShell(
          title: 'Flat workspaces',
          actions: [
            if (!isViewer)
              OutlinedButton.icon(
                onPressed: _isExporting
                    ? null
                    : () => _showExportOptions(context),
                icon: const Icon(Icons.download_rounded),
                label: Text(l.downloadReports),
              ),
            if (canEdit)
              FilledButton.icon(
                onPressed: _showAddFlatSheet,
                icon: const Icon(Icons.add_rounded),
                label: Text(l.addFlat),
              ),
          ],
          child: _flats.isEmpty
              ? DesktopSurfaceCard(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apartment_outlined,
                          size: 54,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          canEdit ? l.noFlatsYet : l.noFlatsAdded,
                          textAlign: TextAlign.center,
                          style: AppTheme.body.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisExtent: 180,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: _flats.length,
                  itemBuilder: (context, index) {
                    final flat = Map<String, dynamic>.from(_flats[index]);
                    final flatId = flat['id']?.toString() ?? '';
                    final unreadCount = currentUser == null || flatId.isEmpty
                        ? 0
                        : unreadTracker.unseenFlatItemCount(
                            userId: currentUser.id,
                            projectId: widget.projectId,
                            flatId: flatId,
                            tasks: tasksByFlatId[flatId] ?? const [],
                          );
                    final bool isCompleted = flat['is_completed'] == true;
                    return _FlatCard(
                      flat: flat,
                      isCompleted: isCompleted,
                      unreadCount: unreadCount,
                      canEdit: canEdit,
                      onTap: () => _openFlat(flat),
                      onToggleCompleted: () => _toggleFlatCompleted(flat),
                      onDelete: () => _deleteFlat(flat),
                    );
                  },
                ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              onPressed: _showAddFlatSheet,
              icon: Icon(Icons.add, color: AppTheme.surface),
              label: Text(l.addFlat, style: TextStyle(color: AppTheme.surface)),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isViewer) ...[
              if (_isExporting)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showExportOptions(context),
                    icon: Icon(
                      Icons.download,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                    label: Text(
                      l.downloadReports,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: _flats.isEmpty
                    ? CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.apartment,
                                    size: 48,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    canEdit ? l.noFlatsYet : l.noFlatsAdded,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.body.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: _flats.length,
                        itemBuilder: (context, index) {
                          final flat = Map<String, dynamic>.from(_flats[index]);
                          final flatId = flat['id']?.toString() ?? '';
                          final unreadCount =
                              currentUser == null || flatId.isEmpty
                              ? 0
                              : unreadTracker.unseenFlatItemCount(
                                  userId: currentUser.id,
                                  projectId: widget.projectId,
                                  flatId: flatId,
                                  tasks: tasksByFlatId[flatId] ?? const [],
                                );
                          final bool isCompleted = flat['is_completed'] == true;
                          return _FlatCard(
                            flat: flat,
                            isCompleted: isCompleted,
                            unreadCount: unreadCount,
                            canEdit: canEdit,
                            onTap: () => _openFlat(flat),
                            onToggleCompleted: () => _toggleFlatCompleted(flat),
                            onDelete: () => _deleteFlat(flat),
                          );
                        },
                      ),
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
  final int unreadCount;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onToggleCompleted;
  final VoidCallback onDelete;

  const _FlatCard({
    required this.flat,
    required this.isCompleted,
    required this.unreadCount,
    required this.canEdit,
    required this.onTap,
    required this.onToggleCompleted,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isWindows = isWindowsDesktop;
    return Material(
      color: isCompleted ? AppTheme.success.withAlpha(30) : AppTheme.surface,
      borderRadius: BorderRadius.circular(isWindows ? 22 : 12),
      elevation: isWindows ? 0 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(isWindows ? 22 : 12),
        onTap: onTap,
        child: Stack(
          children: [
            if (unreadCount > 0)
              Positioned(
                top: 0,
                left: 0,
                child: UnreadBadge(count: unreadCount),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.apartment,
                    color: isCompleted ? AppTheme.success : AppTheme.primary,
                    size: isWindows ? 34 : 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    flat['flat_number']?.toString() ?? '?',
                    style: AppTheme.heading.copyWith(
                      fontSize: isWindows ? 24 : 20,
                      color: isCompleted
                          ? AppTheme.success
                          : AppTheme.textPrimary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
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
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
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
                          Text(isCompleted ? l.unmarkDone : l.markDone),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
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
