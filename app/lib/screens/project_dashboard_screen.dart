import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'attendance_screen.dart';
import 'calendar_screen.dart';
import 'tasks_tab.dart';

class ProjectDashboardScreen extends StatefulWidget {
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
  State<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Isolated Stack mapping precise structural context directly below
    final List<Widget> pages = [
      TasksTab(projectId: widget.projectId),
      CalendarScreen(projectId: widget.projectId),
      AttendanceScreen(projectId: widget.projectId),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.projectName ?? 'Active Workspace', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (widget.projectLocation != null && widget.projectLocation!.isNotEmpty)
              Text(widget.projectLocation!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Pops out of the specific Project Workspace entirely back to Global Projects Landing
          onPressed: () => context.pop(),
        ),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        backgroundColor: AppTheme.surface,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.co_present), label: 'Attendance'),
        ],
      ),
    );
  }
}
