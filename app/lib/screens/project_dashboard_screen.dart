import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../state/auth_provider.dart';
import 'attendance_screen.dart';
import 'calendar_screen.dart';
import 'tasks_tab.dart';
import 'gallery_tab.dart';

class ProjectDashboardScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String? projectName;
  final String? projectLocation;

  const ProjectDashboardScreen({
    super.key,
    required this.projectId,
    this.projectName,
    this.projectLocation,
  });

  @override
  ConsumerState<ProjectDashboardScreen> createState() =>
      _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState
    extends ConsumerState<ProjectDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).currentUser;
    // Treat null user as viewer (safest default while state is loading)
    final isViewer = currentUser == null || currentUser.role.value == 'viewer';

    // Isolated Stack mapping precise structural context directly below
    final List<Widget> pages = [
      TasksTab(projectId: widget.projectId),
      CalendarScreen(projectId: widget.projectId),
      if (!isViewer) AttendanceScreen(projectId: widget.projectId),
      if (!isViewer)
        GalleryTab(
          projectId: widget.projectId,
          projectName: widget.projectName ?? 'Unknown_Project',
        ),
    ];

    // Clamp the tab index so it never exceeds the available pages.
    // This prevents a crash when the role changes mid-session and
    // the pages list shrinks (e.g. viewer → fewer tabs).
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.projectName ?? 'Active Workspace',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.projectLocation != null &&
                widget.projectLocation!.isNotEmpty)
              Text(
                widget.projectLocation!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Pops out of the specific Project Workspace entirely back to Global Projects Landing
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        backgroundColor: AppTheme.surface,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          if (!isViewer)
            const BottomNavigationBarItem(
              icon: Icon(Icons.co_present),
              label: 'Attendance',
            ),
          if (!isViewer)
            const BottomNavigationBarItem(
              icon: Icon(Icons.photo_library),
              label: 'Progress',
            ),
        ],
      ),
    );
  }
}
