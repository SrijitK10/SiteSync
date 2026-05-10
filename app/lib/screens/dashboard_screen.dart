import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/platform_utils.dart';
import '../theme/app_theme.dart';

class ActivityEvent {
  final DateTime timestamp;
  final String action;
  final String userName;
  final String taskTitle;
  final String projectName;
  final String flatNumber;
  final bool isCompletion;

  ActivityEvent({
    required this.timestamp,
    required this.action,
    required this.userName,
    required this.taskTitle,
    required this.projectName,
    required this.flatNumber,
    required this.isCompletion,
  });
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ActivityEvent> _activityLog = [];
  Map<String, List<Map<String, dynamic>>> _pendingTasksByProject = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await apiClient.get('/tasks/all');
      final data = res.data;
      if (data is List) {
        _processData(List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _processData(List<Map<String, dynamic>> tasks) {
    final List<ActivityEvent> log = [];
    final Map<String, List<Map<String, dynamic>>> pending = {};

    for (var task in tasks) {
      final projectName = task['project']?['name']?.toString() ?? 'Unknown Project';
      final flatNumber = task['flat']?['flat_number']?.toString() ?? '-';
      final taskTitle = task['title']?.toString() ?? 'Untitled Task';
      final status = task['status']?.toString() ?? 'todo';
      final createdBy = task['createdBy']?['name']?.toString() ?? 'Unknown User';
      final assignee = task['assignee']?['name']?.toString() ?? 'Unknown User';

      // 1. Created Event
      if (task['created_at'] != null) {
        try {
          final createdAt = DateTime.parse(task['created_at'].toString());
          log.add(ActivityEvent(
            timestamp: createdAt,
            action: 'Task Added',
            userName: createdBy,
            taskTitle: taskTitle,
            projectName: projectName,
            flatNumber: flatNumber,
            isCompletion: false,
          ));
        } catch (_) {}
      }

      // 2. Completed Event
      if (status == 'completed' && task['completed_at'] != null) {
        try {
          final completedAt = DateTime.parse(task['completed_at'].toString());
          log.add(ActivityEvent(
            timestamp: completedAt,
            action: 'Task Completed',
            userName: assignee, // Usually the assignee completes it
            taskTitle: taskTitle,
            projectName: projectName,
            flatNumber: flatNumber,
            isCompletion: true,
          ));
        } catch (_) {}
      }

      // 3. Pending tasks grouping
      if (status != 'completed') {
        pending.putIfAbsent(projectName, () => []).add(task);
      }
    }

    // Sort log descending by timestamp
    log.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) {
      setState(() {
        _activityLog = log;
        _pendingTasksByProject = pending;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0 && now.day == dt.day) {
      return 'Today, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && now.day != dt.day)) {
      return 'Yesterday, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildActivityLog() {
    if (_activityLog.isEmpty) {
      return const Center(child: Text('No recent activity.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activityLog.length,
      itemBuilder: (context, index) {
        final event = _activityLog[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final Color cardColor = Theme.of(context).colorScheme.surface;
        final Color accentColor = event.isCompletion ? AppTheme.success : AppTheme.primary;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: accentColor.withValues(alpha: 0.15),
              child: Icon(
                event.isCompletion ? Icons.check_circle_outline : Icons.add_task_outlined,
                color: accentColor,
              ),
            ),
            title: RichText(
              text: TextSpan(
                style: AppTheme.body.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
                children: [
                  TextSpan(
                    text: '${event.userName} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: event.isCompletion ? 'completed ' : 'added ',
                  ),
                  TextSpan(
                    text: event.taskTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.top(6),
              child: Row(
                children: [
                  Icon(Icons.apartment_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Flat ${event.flatNumber} • ${event.projectName}',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Text(
              _formatDate(event.timestamp),
              style: AppTheme.body.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingTasks() {
    if (_pendingTasksByProject.isEmpty) {
      return const Center(child: Text('No pending tasks.'));
    }

    final projectNames = _pendingTasksByProject.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projectNames.length,
      itemBuilder: (context, index) {
        final projectName = projectNames[index];
        final tasks = _pendingTasksByProject[projectName]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.folder_open_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      projectName,
                      style: AppTheme.heading.copyWith(fontSize: 18),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length} pending',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...tasks.map((task) {
                final taskTitle = task['title']?.toString() ?? 'Untitled';
                final flatNumber = task['flat']?['flat_number']?.toString() ?? '-';
                String dateStr = '';
                if (task['created_at'] != null) {
                  try {
                    dateStr = _formatDate(DateTime.parse(task['created_at'].toString()));
                  } catch (_) {}
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      taskTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Flat $flatNumber${dateStr.isNotEmpty ? ' • Added $dateStr' : ''}',
                      style: AppTheme.body.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Icon(
                      Icons.pending_actions_rounded,
                      color: AppTheme.warning,
                      size: 20,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  'Activity Log',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              Expanded(child: _buildActivityLog()),
            ],
          ),
        ),
        Container(width: 1, color: Theme.of(context).dividerColor),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  'Pending Tasks',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              Expanded(child: _buildPendingTasks()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Activity Log', icon: Icon(Icons.history)),
              Tab(text: 'Pending Tasks', icon: Icon(Icons.pending_actions)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: _fetchData,
                  child: _buildActivityLog(),
                ),
                RefreshIndicator(
                  onRefresh: _fetchData,
                  child: _buildPendingTasks(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Operations Dashboard'),
        backgroundColor: AppTheme.surface,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Failed to load dashboard data:\n$_errorMessage', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800 || isWindowsDesktop) {
                        return _buildDesktopLayout();
                      }
                      return _buildMobileLayout();
                    },
                  ),
      ),
    );
  }
}
