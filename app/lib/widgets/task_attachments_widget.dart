import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../theme/app_theme.dart';
import '../services/api_client.dart';

const String _cloudName = 'decj8mbhf';
const String _uploadPreset = 'rupayan';

class TaskAttachmentsWidget extends StatefulWidget {
  final String taskId;
  final bool canEdit;

  const TaskAttachmentsWidget({
    super.key,
    required this.taskId,
    required this.canEdit,
  });

  @override
  State<TaskAttachmentsWidget> createState() => _TaskAttachmentsWidgetState();
}

class _TaskAttachmentsWidgetState extends State<TaskAttachmentsWidget> {
  List<dynamic> _attachments = [];
  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _fetchAttachments();
  }

  Future<void> _fetchAttachments() async {
    try {
      final res = await apiClient.get('/tasks/${widget.taskId}/attachments');
      if (mounted) {
        setState(() {
          _attachments = List<dynamic>.from(res.data as List<dynamic>);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load attachments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _classifyFile(String name, String? mime) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'pdf';
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic')) return 'image';
    if (mime != null && mime.startsWith('image/')) return 'image';
    return 'document';
  }

  Future<void> _pickAndUpload() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pick Images'),
              onTap: () => Navigator.pop(ctx, 'images'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Pick Files (PDF, Docs)'),
              onTap: () => Navigator.pop(ctx, 'files'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    List<File> files = [];

    if (choice == 'images') {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage();
      files = picked.map((x) => File(x.path)).toList();
    } else if (choice == 'camera') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked != null) files = [File(picked.path)];
    } else {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'txt',
          'csv',
          'png',
          'jpg',
          'jpeg',
        ],
      );
      if (result != null) {
        files = result.paths.whereType<String>().map((p) => File(p)).toList();
      }
    }

    if (files.isEmpty) return;
    await _uploadFiles(files);
  }

  Future<void> _uploadFiles(List<File> files) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    final cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);

    for (int i = 0; i < files.length; i++) {
      try {
        final file = files[i];
        final name = file.path.split('/').last;
        final fileType = _classifyFile(name, null);
        final resourceType = fileType == 'image'
            ? CloudinaryResourceType.Image
            : CloudinaryResourceType.Auto;

        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            resourceType: resourceType,
            folder: 'sitesync/tasks/${widget.taskId}',
          ),
        );

        await apiClient.post('/tasks/${widget.taskId}/attachments', data: {
          'url': response.secureUrl,
          'displayName': name,
          'originalName': name,
          'fileType': fileType,
          'mimeType': null,
          'fileSize': file.lengthSync(),
        });

        if (mounted) {
          setState(() => _uploadProgress = (i + 1) / files.length);
        }
      } catch (e) {
        debugPrint('Error uploading file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload: ${files[i].path.split('/').last}')),
          );
        }
      }
    }

    if (mounted) {
      setState(() => _isUploading = false);
    }
    await _fetchAttachments();
  }

  /// Called externally when files are shared into the app.
  Future<void> uploadSharedFiles(List<File> files) async {
    await _uploadFiles(files);
  }

  Future<void> _renameAttachment(Map<String, dynamic> attachment) async {
    final controller = TextEditingController(
      text: attachment['display_name'] ?? '',
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;

    try {
      await apiClient.patch(
        '/tasks/attachments/${attachment['id']}/rename',
        data: {'displayName': newName},
      );
      _fetchAttachments();
    } catch (e) {
      debugPrint('Error renaming attachment: $e');
    }
  }

  Future<void> _deleteAttachment(Map<String, dynamic> attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Delete "${attachment['display_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await apiClient.delete('/tasks/attachments/${attachment['id']}');
      _fetchAttachments();
    } catch (e) {
      debugPrint('Error deleting attachment: $e');
    }
  }

  Future<void> _openAttachment(Map<String, dynamic> attachment) async {
    final url = attachment['url'] as String? ?? '';
    final name = attachment['display_name'] as String? ?? 'file';
    final type = attachment['file_type'] as String? ?? 'document';

    if (type == 'image') {
      _showImageViewer(url, name);
      return;
    }

    // Download and open with system viewer
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$name';
      await Dio().download(url, filePath);
      await OpenFilex.open(filePath);
    } catch (e) {
      debugPrint('Error opening file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
  }

  void _showImageViewer(String url, String name) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'pdf':
        return Colors.red;
      case 'image':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _formatSize(dynamic bytes) {
    if (bytes == null) return '';
    final b = bytes is int ? bytes : int.tryParse(bytes.toString()) ?? 0;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Attachments',
              style: AppTheme.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            if (_attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_attachments.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            if (widget.canEdit)
              _isUploading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        strokeWidth: 2,
                      ),
                    )
                  : InkWell(
                      onTap: _pickAndUpload,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else if (_attachments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No files attached',
              style: AppTheme.body.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          )
        else
          ..._attachments.map((a) {
            final att = Map<String, dynamic>.from(a as Map);
            final type = att['file_type'] as String? ?? 'document';
            final name = att['display_name'] as String? ?? 'File';
            final size = _formatSize(att['file_size']);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => _openAttachment(att),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _colorForType(type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: type == 'image'
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  att['url'] ?? '',
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(_iconForType(type), size: 20, color: _colorForType(type)),
                                ),
                              )
                            : Icon(_iconForType(type), size: 20, color: _colorForType(type)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTheme.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (size.isNotEmpty)
                              Text(
                                size,
                                style: AppTheme.body.copyWith(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.canEdit) ...[
                        InkWell(
                          onTap: () => _renameAttachment(att),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _deleteAttachment(att),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
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
    );
  }
}
