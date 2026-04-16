import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';

class CalendarScreen extends StatefulWidget {
  final String projectId;
  const CalendarScreen({super.key, required this.projectId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<dynamic> _rawTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final res = await apiClient.get('/tasks?projectId=${widget.projectId}');
      if (mounted) {
        setState(() {
          _rawTasks = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load tasks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Infinite Visual Rollover Engine natively projecting pending Tasks endlessly
  List<dynamic> _getTasksForDay(DateTime day) {
    if (_rawTasks.isEmpty) return [];

    // Normalize into explicit YYYY-MM-DD bounds dropping clock drift interference
    final dayStr = day.toIso8601String().split('T')[0];

    List<dynamic> tasks = [];
    for (var t in _rawTasks) {
      final rawCreated = t['created_at'] as String?;
      final rawCompleted = t['completed_at'] as String?;

      if (rawCreated == null) continue;

      // Strip time artifacts natively enforcing YYYY-MM-DD
      final createdStr = rawCreated.split('T')[0];
      final completedStr = rawCompleted?.split('T')[0];

      // If the Calendar Day is functionally ON or AFTER the task creation boundary
      if (dayStr.compareTo(createdStr) >= 0) {
        // If it got natively checked off eventually
        if (completedStr != null) {
          // If the Calendar day physically lands BEFORE or ON the explicit completed date!
          if (dayStr.compareTo(completedStr) <= 0) {
            tasks.add(t);
          }
        } else {
          // It was completely ignored and sits 'todo' or 'in_progress'. Rollover infinitely immediately up to present natively!
          tasks.add(t);
        }
      }
    }
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _selectedDay != null
        ? _getTasksForDay(_selectedDay!)
        : [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: AppTheme.surface,
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: _getTasksForDay,
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: AppTheme.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Assignments for ${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}',
                    style: AppTheme.heading.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: selectedTasks.isEmpty
                      ? const Center(
                          child: Text(
                            'No tracking events logically spanning this bound.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: selectedTasks.length,
                          itemBuilder: (context, index) {
                            final t = selectedTasks[index];
                            final bool isDone = t['status'] == 'completed';
                            final bool completedToday =
                                isDone &&
                                t['completed_at'] ==
                                    _selectedDay!.toIso8601String().split(
                                      'T',
                                    )[0];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                tileColor: AppTheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: isDone
                                      ? AppTheme.success.withAlpha(50)
                                      : AppTheme.accent.withAlpha(50),
                                  child: Icon(
                                    isDone
                                        ? Icons.check
                                        : Icons.local_fire_department,
                                    color: isDone
                                        ? AppTheme.success
                                        : AppTheme.accent,
                                  ),
                                ),
                                title: Text(
                                  () {
                                    final title = t['title'] ?? 'Untitled';
                                    final flatNumber = t['flat']?['flat_number']
                                        ?.toString();
                                    return flatNumber != null &&
                                            flatNumber.isNotEmpty
                                        ? '$flatNumber: $title'
                                        : title;
                                  }(),
                                  style: AppTheme.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Text(
                                  completedToday
                                      ? 'Checked off today!'
                                      : (isDone
                                            ? 'Checked off historically'
                                            : 'Pending & Rolling over'),
                                  style: AppTheme.label,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
