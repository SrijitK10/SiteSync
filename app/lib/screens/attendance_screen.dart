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
  final _labourersController = TextEditingController();
  final _mistrisController = TextEditingController();
  String? _selectedContractor;
  
  List<dynamic> _contractors = [];
  bool _isLoadingContractors = true;

  final List<Map<String, dynamic>> _records = [];
  
  bool _isExporting = false;
  bool _isSyncing = false;
  
  String _siteAddress = 'Loading Location...';
  String _projectName = 'Loading Project...';
  bool _isLoadingProject = true;

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
    _fetchContractors();
  }

  Future<void> _fetchContractors() async {
    try {
      final res = await apiClient.get('/contractors');
      if (mounted) {
        setState(() {
          _contractors = res.data;
          _isLoadingContractors = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load contractors: $e');
      if (mounted) setState(() => _isLoadingContractors = false);
    }
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
    if (_selectedContractor == null) return;
    
    final labourers = int.tryParse(_labourersController.text.trim()) ?? 0;
    final mistris = int.tryParse(_mistrisController.text.trim()) ?? 0;

    setState(() {
      _records.insert(0, {
        'contractor_name': _selectedContractor,
        'labourers_count': labourers,
        'mistris_count': mistris,
        'date': DateTime.now().toIso8601String(),
        'project': _projectName,
      });
      _selectedContractor = null;
      _labourersController.clear();
      _mistrisController.clear();
    });
  }

  void _editRecordLocal(int index) {
    final record = _records[index];
    setState(() {
      _selectedContractor = record['contractor_name'];
      _labourersController.text = record['labourers_count'].toString();
      _mistrisController.text = record['mistris_count'].toString();
      _records.removeAt(index);
    });
  }

  void _removeRecordLocal(int index) {
    setState(() {
      _records.removeAt(index);
    });
  }

  Future<void> _submitAttendanceToCloud() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one worker first.')));
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final formattedRecords = _records.map((r) => {
        'contractor_name': r['contractor_name'],
        'labourers_count': r['labourers_count'],
        'mistris_count': r['mistris_count'],
      }).toList();
      
      await apiClient.post('/attendance/bulk', data: {
        'projectId': widget.projectId,
        'siteAddress': _siteAddress,
        'records': formattedRecords,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Roster securely synced to Database!'),
          backgroundColor: AppTheme.success,
        ));
        setState(() {
          _records.clear();
          _selectedContractor = null;
          _labourersController.clear();
          _mistrisController.clear();
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
        TextCellValue('Contractor'),
        TextCellValue('Labourers'),
        TextCellValue('Mistris'),
        TextCellValue('Mapped Project Location'),
        TextCellValue('Timestamp (Server Locked)'),
        TextCellValue('Logged By'),
      ]);

      for (var r in remoteRecords) {
        sheetObject.appendRow([
          TextCellValue(r['contractor_name'] ?? 'Unknown'),
          TextCellValue(r['labourers_count']?.toString() ?? '0'),
          TextCellValue(r['mistris_count']?.toString() ?? '0'),
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

  Future<void> _addContractorConfig(String name) async {
    try {
      await apiClient.post('/contractors', data: {'name': name});
      _fetchContractors();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contractor Added')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add contractor: $e')));
    }
  }

  Future<void> _deleteContractorConfig(String id) async {
    try {
      await apiClient.delete('/contractors/$id');
      _fetchContractors();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contractor Removed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove contractor: $e')));
    }
  }

  void _showManageContractorsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final localController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Manage Contractors', style: AppTheme.heading),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'NEW CONTRACTOR NAME',
                      hint: 'Type here...',
                      controller: localController,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppTheme.primary, size: 36),
                    onPressed: () {
                      if (localController.text.trim().isNotEmpty) {
                        _addContractorConfig(localController.text.trim());
                        localController.clear();
                        Navigator.pop(ctx);
                        _fetchContractors();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              Expanded(
                child: _contractors.isEmpty 
                  ? const Center(child: Text('No contractors found.'))
                  : ListView.builder(
                      itemCount: _contractors.length,
                      itemBuilder: (c, i) {
                        final contractor = _contractors[i];
                        return ListTile(
                          title: Text(contractor['name']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteContractorConfig(contractor['id']);
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      },
                    ),
              )
            ],
          ),
        );
      },
    );
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showManageContractorsDialog(context),
                          icon: const Icon(Icons.group, size: 18, color: AppTheme.accent),
                          label: const Text('Contractors', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600)),
                        ),
                        TextButton.icon(
                          onPressed: () => _showExportOptions(context),
                          icon: const Icon(Icons.download, size: 18, color: AppTheme.primary),
                          label: const Text('Reports', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
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
                          _isLoadingContractors 
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<String>(
                                value: _selectedContractor,
                                decoration: const InputDecoration(
                                  labelText: 'CONTRACTOR',
                                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                                ),
                                dropdownColor: AppTheme.surface,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                items: _contractors.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c['name'],
                                    child: Text(c['name']),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedContractor = val;
                                  });
                                },
                              ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'LABOURERS',
                                  hint: '0',
                                  controller: _labourersController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppTextField(
                                  label: 'MISTRIS',
                                  hint: '0',
                                  controller: _mistrisController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                leading: const Icon(Icons.engineering, color: AppTheme.accent),
                                title: Text(r['contractor_name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Labourers: ${r['labourers_count']} • Mistris: ${r['mistris_count']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppTheme.primary),
                                      onPressed: () => _editRecordLocal(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _removeRecordLocal(index),
                                    ),
                                  ],
                                ),
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
