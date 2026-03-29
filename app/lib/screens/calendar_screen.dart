import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  final String projectId;
  const CalendarScreen({super.key, required this.projectId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock data representing shifts mapped to days
  final Map<DateTime, List<String>> _shifts = {
    DateTime.now(): ['Downtown Plaza: 08:00 AM - 04:00 PM'],
    DateTime.now().add(const Duration(days: 1)): ['Harbor Apartments: 09:00 AM - 05:00 PM'],
  };

  List<String> _getShiftsForDay(DateTime day) {
    // Exact match ignoring time
    for (var key in _shifts.keys) {
      if (isSameDay(key, day)) {
        return _shifts[key]!;
      }
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final selectedShifts = _selectedDay != null ? _getShiftsForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Schedule'),
      ),
      body: Column(
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
              eventLoader: _getShiftsForDay,
              calendarStyle: const CalendarStyle(
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
            child: selectedShifts.isEmpty
                ? const Center(child: Text('No shifts scheduled for this day.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedShifts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          tileColor: AppTheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.accent,
                            child: Icon(Icons.work, color: AppTheme.primary),
                          ),
                          title: Text(selectedShifts[index], style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text('Status: Confirmed', style: AppTheme.label),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
