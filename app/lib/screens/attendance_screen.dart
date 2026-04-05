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

class AttendanceScreen extends ConsumerStatefulWidget {
  final String projectId;
  const AttendanceScreen({super.key, required this.projectId});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final _workerNameController = TextEditingController();
  final List<Map<String, String>> _records = [];
  
  bool _isExporting = false;
  bool _isSyncing = false;
  
  String _siteAddress = 'Loading Location...';
  String _projectName = 'Loading Project...';
  bool _isLoadingProject = true;

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
  }

  Future<void> _loadProjectDetails() async {
    try {
      // Isolating API call natively securely locked exclusively to the passed Context ID
      final res = await apiClient.get('/projects/${widget.projectId}');
      if (res.data != null) {
        setState(() {
          _projectName = res.data['name'] ?? 'Attached Project';
          _siteAddress = res.data['location'] ?? 'Location Unknown';
        });
      }
    } catch (e) {
      debugPrint('Failed to load project details: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProject = false);
    }
  }

  void _addRecordLocal() {
    final name = _workerNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _records.insert(0, {
        'name': name,
        'date': DateTime.now().toIso8601String(),
        'project': _projectName,
      });
      _workerNameController.clear();
    });
  }

  Future<void> _submitAttendanceToCloud() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one worker first.')));
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final workers = _records.map((r) => r['name']!).toList();
      await apiClient.post('/attendance/bulk', data: {
        'projectId': widget.projectId,
        'siteAddress': _siteAddress,
        'workers': workers,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Roster securely synced to Database!'),
          backgroundColor: AppTheme.success,
        ));
        setState(() {
          _records.clear();
          _workerNameController.clear();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sync: $e')));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _fetchAndExportExcel(String range, {String? startDate, String? endDate}) async {
    setState(() => _isExporting = true);

    try {
      String url = '/attendance?projectId=${widget.projectId}&range=$range';
      if (range == 'custom' && startDate != null && endDate != null) {
        url += '&startDate=$startDate&endDate=$endDate';
      }
      final res = await apiClient.get(url);
      final List<dynamic> remoteRecords = res.data;

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Attendance'];
      excel.setDefaultSheet('Attendance');

      sheetObject.appendRow([
        TextCellValue('Worker Name'),
        TextCellValue('Mapped Project Location'),
        TextCellValue('Timestamp (Server Locked)'),
        TextCellValue('Logged By'),
      ]);

      for (var r in remoteRecords) {
        sheetObject.appendRow([
          TextCellValue(r['worker_name'] ?? 'Unknown'),
          TextCellValue(r['site_address'] ?? 'No Address'),
          TextCellValue(r['date'] ?? ''),
          TextCellValue(r['recorder']?['name'] ?? 'Unknown Admin'),
        ]);
      }

      final directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/Rupayan_${range}_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final List<int>? fileBytes = excel.save();
      
      if (fileBytes != null) {
        File dataFile = File(filePath);
        await dataFile.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(filePath)], text: 'Rupayan $range Attendance Cloud Export');
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export extraction failed: $e')));
      debugPrint('Export error: $e');
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
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
            ),
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
                child: Text('Download Central Database Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.today, color: AppTheme.accent),
                title: const Text('Export Daily Roster'),
                onTap: () { Navigator.pop(context); _fetchAndExportExcel('daily'); },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: AppTheme.accent),
                title: const Text('Export Weekly Roster'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      // We remove the AppBar completely because it's tightly embedded inside the ProjectDashboardScreen IndexedStack natively!
      body: _isLoadingProject 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          AppTextField(
                            label: 'WORKER NAME',
                            hint: 'Type worker name',
                            controller: _workerNameController,
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            text: 'Add to Temporary Roster',
                            onPressed: _addRecordLocal,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today\'s Roster', style: AppTheme.heading.copyWith(fontSize: 18)),
                    if (_records.isNotEmpty)
                      Text('${_records.length} Pending Sync', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _records.isEmpty
                      ? const Center(child: Text('No attendance recorded yet today.'))
                      : ListView.builder(
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            final r = _records[index];
                            return Card(
                              color: AppTheme.surface,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: AppTheme.accent),
                                title: Text(r['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: const Icon(Icons.sync_problem, color: Colors.orange),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                _isSyncing
                  ? const Center(child: CircularProgressIndicator())
                  : AppButton(
                      text: 'Submit ALL to Database',
                      onPressed: _submitAttendanceToCloud,
                    ),
              ],
            ),
          ),
    );
  }
}
