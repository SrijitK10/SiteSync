import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'attendance_screen.dart';
import 'calendar_screen.dart';

// TasksTab implementation logic securely scoped to projectId
class TasksTab extends StatelessWidget {
  final String projectId;
  const TasksTab({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Live Tasks for this Project will appear here.'));
  }
}

class ProjectDashboardScreen extends StatefulWidget {
  final String projectId;
  
  const ProjectDashboardScreen({super.key, required this.projectId});

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
        title: const Text('Active Workspace'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Pops out of the specific Project Workspace entirely back to Global Projects Landing
          onPressed: () => context.pop(),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
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
