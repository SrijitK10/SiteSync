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
      final res = await apiClient.get('/tasks/global/all');
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
      final completedBy = task['completedBy']?['name']?.toString() ?? assignee;

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
            userName: completedBy,
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
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _buildActivityTile(BuildContext context, ActivityEvent event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final Color accentColor = event.isCompletion ? AppTheme.success : Theme.of(context).colorScheme.primary;
    final Color secondaryColor = isDark ? const Color(0xFFA7B5CB) : const Color(0xFF66758B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTheme.body.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
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
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.apartment, size: 14, color: secondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Flat ${event.flatNumber}  •  ',
                        style: AppTheme.body.copyWith(
                          color: secondaryColor,
                          fontSize: 13,
                        ),
                      ),
                      Icon(Icons.folder_open, size: 14, color: secondaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.projectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body.copyWith(
                            color: secondaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog() {
    if (_activityLog.isEmpty) {
      return const Center(child: Text('No recent activity.'));
    }

    // Group events by formatted date (dd/mm/yyyy)
    final Map<String, List<ActivityEvent>> groupedEvents = {};
    for (var event in _activityLog) {
      final dateStr = _formatDate(event.timestamp);
      groupedEvents.putIfAbsent(dateStr, () => []).add(event);
    }

    final List<Widget> listItems = [];
    
    for (final dateStr in groupedEvents.keys) {
      // Date Header
      listItems.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12, left: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: AppTheme.heading.copyWith(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
      
      // Events for this date
      for (final event in groupedEvents[dateStr]!) {
        listItems.add(_buildActivityTile(context, event));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: listItems.length,
      itemBuilder: (context, index) => listItems[index],
    );
  }

  Widget _buildPendingTasks() {
    if (_pendingTasksByProject.isEmpty) {
      return const Center(child: Text('No pending tasks.'));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondaryColor = isDark ? const Color(0xFFA7B5CB) : const Color(0xFF66758B);
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
                padding: const EdgeInsets.only(left: 16, bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        projectName,
                        style: AppTheme.heading.copyWith(fontSize: 18),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${tasks.length} pending',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 13,
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

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      taskTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.apartment, size: 14, color: secondaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'Flat $flatNumber',
                            style: AppTheme.body.copyWith(
                              color: secondaryColor,
                              fontSize: 13,
                            ),
                          ),
                          if (dateStr.isNotEmpty) ...[
                            Text(
                              '  •  ',
                              style: AppTheme.body.copyWith(
                                color: secondaryColor,
                                fontSize: 13,
                              ),
                            ),
                            Icon(Icons.calendar_today, size: 12, color: secondaryColor),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: AppTheme.body.copyWith(
                                color: secondaryColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
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
    // Ensure AppTheme._isDark is in sync with the current brightness
    AppTheme.syncWithContext(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Image.asset('assets/images/rppl.png', height: 56),
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
