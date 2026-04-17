import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

const String _cloudName = 'decj8mbhf';
const String _uploadPreset = 'rupayan';

/// Full-screen picker shown when files are shared into the app.
/// Hierarchy: Projects → Flats → Tasks → Upload
class ShareToTaskScreen extends ConsumerStatefulWidget {
  final List<File> sharedFiles;

  const ShareToTaskScreen({super.key, required this.sharedFiles});

  @override
  ConsumerState<ShareToTaskScreen> createState() => _ShareToTaskScreenState();
}

class _ShareToTaskScreenState extends ConsumerState<ShareToTaskScreen> {
  // Navigation state
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _flats = [];
  List<Map<String, dynamic>> _tasks = [];

  Map<String, dynamic>? _selectedProject;
  Map<String, dynamic>? _selectedFlat;
  Map<String, dynamic>? _selectedTask;

  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0;

  // 0 = projects, 1 = flats, 2 = tasks
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiClient.get('/projects');
      final list = (res.data as List<dynamic>)
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
      if (mounted) setState(() { _projects = list; _isLoading = false; });
    } catch (e) {
      debugPrint('Error fetching projects: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFlats(String projectId) async {
    setState(() { _isLoading = true; _step = 1; });
    try {
      final res = await apiClient.get('/flats?projectId=$projectId');
      final list = (res.data as List<dynamic>)
          .map((f) => Map<String, dynamic>.from(f as Map))
          .toList();
      if (mounted) setState(() { _flats = list; _isLoading = false; });
    } catch (e) {
      debugPrint('Error fetching flats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTasks(String projectId, String flatId) async {
    setState(() { _isLoading = true; _step = 2; });
    try {
      final res = await apiClient.get('/tasks?projectId=$projectId&flatId=$flatId');
      final list = (res.data as List<dynamic>)
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList();
      if (mounted) setState(() { _tasks = list; _isLoading = false; });
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadToTask(Map<String, dynamic> task) async {
    setState(() {
      _selectedTask = task;
      _isUploading = true;
      _uploadProgress = 0;
    });

    final taskId = task['id']?.toString() ?? '';
    final cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

    int success = 0;
    for (int i = 0; i < widget.sharedFiles.length; i++) {
      try {
        final file = widget.sharedFiles[i];
        final name = file.path.split('/').last;
        final isImage = _isImageFile(name);

        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            resourceType: isImage ? CloudinaryResourceType.Image : CloudinaryResourceType.Auto,
            folder: 'sitesync/tasks/$taskId',
          ),
        );

        await apiClient.post('/tasks/$taskId/attachments', data: {
          'url': response.secureUrl,
          'displayName': name,
          'originalName': name,
          'fileType': isImage ? 'image' : _classifyFile(name),
          'fileSize': file.lengthSync(),
        });

        success++;
        if (mounted) setState(() => _uploadProgress = (i + 1) / widget.sharedFiles.length);
      } catch (e) {
        debugPrint('Failed to upload shared file: $e');
      }
    }

    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$success/${widget.sharedFiles.length} files uploaded')),
      );
      Navigator.of(context).pop();
    }
  }

  bool _isImageFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
        lower.endsWith('.png') || lower.endsWith('.gif') ||
        lower.endsWith('.webp') || lower.endsWith('.heic');
  }

  String _classifyFile(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'pdf';
    if (_isImageFile(name)) return 'image';
    return 'document';
  }

  void _goBack() {
    if (_step == 2) {
      setState(() { _step = 1; _selectedFlat = _selectedFlat; });
    } else if (_step == 1) {
      setState(() { _step = 0; _selectedProject = null; });
    } else {
      Navigator.of(context).pop();
    }
  }

  String get _title {
    if (_step == 2) return 'Select Task';
    if (_step == 1) return 'Select Flat';
    return 'Select Project';
  }

  String get _subtitle {
    final parts = <String>[];
    if (_selectedProject != null) parts.add(_selectedProject!['name'] ?? '');
    if (_selectedFlat != null) parts.add('Flat ${_selectedFlat!['flat_number'] ?? ''}');
    return parts.join(' → ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_subtitle.isNotEmpty)
              Text(_subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: _uploadProgress > 0 ? _uploadProgress : null),
                  const SizedBox(height: 16),
                  Text(
                    'Uploading ${widget.sharedFiles.length} file(s)...',
                    style: AppTheme.body,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To: ${_selectedTask?['title'] ?? 'Task'}',
                    style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildList(),
    );
  }

  Widget _buildList() {
    if (_step == 0) return _buildProjectList();
    if (_step == 1) return _buildFlatList();
    return _buildTaskList();
  }

  Widget _buildProjectList() {
    if (_projects.isEmpty) {
      return const Center(child: Text('No projects found'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilePreviewBar(),
        Expanded(
          child: ListView.builder(
            itemCount: _projects.length,
            itemBuilder: (ctx, i) {
              final p = _projects[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Icon(Icons.business, color: AppTheme.primary),
                ),
                title: Text(p['name'] ?? '', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(p['location'] ?? '', style: AppTheme.body.copyWith(color: AppTheme.textSecondary, fontSize: 13)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _selectedProject = p;
                  _fetchFlats(p['id'].toString());
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlatList() {
    if (_flats.isEmpty) {
      return const Center(child: Text('No flats found'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilePreviewBar(),
        Expanded(
          child: ListView.builder(
            itemCount: _flats.length,
            itemBuilder: (ctx, i) {
              final f = _flats[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.door_front_door_outlined, color: Colors.blue),
                ),
                title: Text('Flat ${f['flat_number'] ?? ''}', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _selectedFlat = f;
                  _fetchTasks(_selectedProject!['id'].toString(), f['id'].toString());
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    if (_tasks.isEmpty) {
      return const Center(child: Text('No tasks found'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilePreviewBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Tap a task to upload ${widget.sharedFiles.length} file(s)',
            style: AppTheme.body.copyWith(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (ctx, i) {
              final t = _tasks[i];
              final isDone = t['status'] == 'completed';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDone
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  child: Icon(
                    isDone ? Icons.check_circle : Icons.circle_outlined,
                    color: isDone ? Colors.green : Colors.orange,
                  ),
                ),
                title: Text(
                  t['title'] ?? 'Untitled',
                  style: AppTheme.body.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  t['created_at'] ?? '',
                  style: AppTheme.body.copyWith(color: AppTheme.textSecondary, fontSize: 12),
                ),
                trailing: const Icon(Icons.upload_file),
                onTap: () => _uploadToTask(t),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreviewBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.surface,
      child: Row(
        children: [
          Icon(Icons.attach_file, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.sharedFiles.length == 1
                  ? widget.sharedFiles.first.path.split('/').last
                  : '${widget.sharedFiles.length} files to upload',
              style: AppTheme.body.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
