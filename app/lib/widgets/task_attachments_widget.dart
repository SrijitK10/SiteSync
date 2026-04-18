import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../theme/app_theme.dart';
import '../services/browser_file_opener.dart';
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

  /// Returns the persistent directory path for a task's files.
  static Future<String> taskDirPath(String taskId) async {
    final appDir = await getApplicationSupportDirectory();
    return '${appDir.path}/Rupayan/tasks/$taskId';
  }

  /// Legacy storage path used by older app versions.
  static Future<String> legacyTaskDirPath(String taskId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/Rupayan/tasks/$taskId';
  }

  /// Deletes all locally saved files for a task.
  static Future<void> deleteLocalFiles(String taskId) async {
    try {
      final paths = {
        await taskDirPath(taskId),
        await legacyTaskDirPath(taskId),
      };

      for (final path in paths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Error deleting local files for task $taskId: $e');
    }
  }

  @override
  State<TaskAttachmentsWidget> createState() => _TaskAttachmentsWidgetState();
}

class _TaskAttachmentsWidgetState extends State<TaskAttachmentsWidget> {
  static const MethodChannel _androidFileOpenerChannel = MethodChannel(
    'com.sitesync.app/file_opener',
  );

  List<dynamic> _attachments = [];
  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0;

  String _localFileName(String displayName, String originalName) {
    final sanitizedName = displayName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    final ext = _extractExtension(originalName);
    if (ext.isEmpty) return sanitizedName;

    final lowerName = sanitizedName.toLowerCase();
    final lowerExt = ext.toLowerCase();
    if (lowerName.endsWith(lowerExt)) {
      return sanitizedName;
    }

    return '$sanitizedName$ext';
  }

  String _cacheFileNameForAttachment(Map<String, dynamic> attachment) {
    final attachmentId = attachment['id']?.toString().trim();
    final originalName =
        attachment['original_name'] as String? ??
        attachment['display_name'] as String? ??
        'file';
    final ext = _extractExtension(originalName);

    if (attachmentId != null && attachmentId.isNotEmpty) {
      return '$attachmentId$ext';
    }

    final displayName = attachment['display_name'] as String? ?? 'file';
    return _localFileName(displayName, originalName);
  }

  List<String> _legacyCacheFileNames(Map<String, dynamic> attachment) {
    final originalName =
        attachment['original_name'] as String? ??
        attachment['display_name'] as String? ??
        'file';
    final displayName = attachment['display_name'] as String? ?? 'file';

    return {
      _localFileName(displayName, originalName),
      _localFileName(originalName, originalName),
      originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_'),
      displayName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_'),
    }.toList();
  }

  Future<String> _resolveLocalAttachmentPath(
    Map<String, dynamic> attachment,
  ) async {
    final taskDir = await TaskAttachmentsWidget.taskDirPath(widget.taskId);
    await Directory(taskDir).create(recursive: true);

    final candidateFileNames = <String>{
      _cacheFileNameForAttachment(attachment),
      ..._legacyCacheFileNames(attachment),
    }.toList();

    final candidateDirs = <String>[
      taskDir,
      await TaskAttachmentsWidget.legacyTaskDirPath(widget.taskId),
    ];

    for (final dir in candidateDirs) {
      for (final fileName in candidateFileNames) {
        final candidatePath = '$dir/$fileName';
        if (await File(candidatePath).exists()) {
          return candidatePath;
        }
      }
    }

    return '$taskDir/${candidateFileNames.first}';
  }

  String _attachmentDisplayName(Map<String, dynamic> attachment) {
    return attachment['display_name'] as String? ?? 'file';
  }

  String _attachmentOriginalName(Map<String, dynamic> attachment) {
    return attachment['original_name'] as String? ??
        _attachmentDisplayName(attachment);
  }

  String? _attachmentMimeType(Map<String, dynamic> attachment) {
    final mimeType = attachment['mime_type'] as String?;
    if (mimeType != null && mimeType.trim().isNotEmpty) {
      return mimeType;
    }
    return _mimeTypeForFileName(_attachmentOriginalName(attachment));
  }

  bool _isTextPreviewable(String fileName, String? mimeType) {
    final lower = fileName.toLowerCase();
    if (mimeType != null && mimeType.startsWith('text/')) {
      return true;
    }

    return lower.endsWith('.txt') ||
        lower.endsWith('.csv') ||
        lower.endsWith('.json') ||
        lower.endsWith('.xml') ||
        lower.endsWith('.log') ||
        lower.endsWith('.md') ||
        lower.endsWith('.yaml') ||
        lower.endsWith('.yml');
  }

  bool _isOfficeDocument(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.ppt') ||
        lower.endsWith('.pptx') ||
        lower.endsWith('.xls') ||
        lower.endsWith('.xlsx');
  }

  bool _isPdfFile(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf');
  }

  String _attachmentUrl(Map<String, dynamic> attachment) {
    return attachment['url'] as String? ?? '';
  }

  bool _isRelativeAttachmentUrl(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null && !uri.hasScheme;
  }

  bool _isCloudinaryAttachmentUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host.contains('cloudinary.com') ?? false;
  }

  Uri? _viewerUriForAttachment(Map<String, dynamic> attachment) {
    final url = _attachmentUrl(attachment);
    if (url.isEmpty) return null;

    final remoteUri = Uri.tryParse(url);
    if (remoteUri == null || !remoteUri.hasScheme) return null;

    final originalName = _attachmentOriginalName(attachment).toLowerCase();
    if (originalName.endsWith('.pdf')) {
      return remoteUri;
    }

    if (_isOfficeDocument(originalName)) {
      return Uri.https('view.officeapps.live.com', '/op/view.aspx', {
        'src': remoteUri.toString(),
      });
    }

    return null;
  }

  void _showMessage(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  Future<File> _ensureLocalAttachmentFile(
    Map<String, dynamic> attachment, {
    bool announceDownload = false,
  }) async {
    final url = _attachmentUrl(attachment);
    if (url.isEmpty) {
      throw StateError('Attachment URL is missing');
    }

    final filePath = await _resolveLocalAttachmentPath(attachment);
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }

    if (announceDownload) {
      _showMessage('Downloading file...', duration: const Duration(seconds: 1));
    }

    await apiClient.download(url, filePath);
    return file;
  }

  Future<bool> _openWithBrowserViewer(Map<String, dynamic> attachment) async {
    final uri = _viewerUriForAttachment(attachment);
    if (uri == null) return false;

    try {
      final preferredMode =
          await supportsLaunchMode(LaunchMode.inAppBrowserView)
          ? LaunchMode.inAppBrowserView
          : LaunchMode.externalApplication;

      return await launchUrl(
        uri,
        mode: preferredMode,
        browserConfiguration: const BrowserConfiguration(showTitle: true),
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      debugPrint('Error opening browser viewer: $e');
      return false;
    }
  }

  Future<bool> _openRemoteAttachment(Map<String, dynamic> attachment) async {
    final url = _attachmentUrl(attachment);
    if (url.isEmpty) return false;
    if (_isRelativeAttachmentUrl(url)) return false;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      debugPrint('Error opening remote attachment: $e');
      return false;
    }
  }

  Future<bool> _openWithSystemViewer(Map<String, dynamic> attachment) async {
    try {
      final localFile = await _ensureLocalAttachmentFile(
        attachment,
        announceDownload: true,
      );

      if (Platform.isAndroid &&
          await _openWithAndroidChooser(
            localFile.path,
            _attachmentMimeType(attachment),
          )) {
        return true;
      }

      final result = await OpenFilex.open(
        localFile.path,
        type: _attachmentMimeType(attachment),
      );

      if (result.type == ResultType.done) {
        return true;
      }

      debugPrint(
        'OpenFilex failed for ${localFile.path}: ${result.type} ${result.message}',
      );
      return false;
    } catch (e) {
      debugPrint('Error opening file locally: $e');
      return false;
    }
  }

  Future<bool> _openWithAndroidChooser(
    String filePath,
    String? mimeType,
  ) async {
    try {
      final result = await _androidFileOpenerChannel
          .invokeMethod<bool>('openFileChooser', {
            'path': filePath,
            'mimeType': mimeType ?? 'application/octet-stream',
            'title': 'Open file with',
          });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Android chooser failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Android chooser error: $e');
      return false;
    }
  }

  Future<Uint8List?> _fetchAttachmentBytes(
    Map<String, dynamic> attachment,
  ) async {
    final url = _attachmentUrl(attachment);
    if (url.isEmpty) return null;

    try {
      final response = await apiClient.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null) return null;
      return data is Uint8List ? data : Uint8List.fromList(data);
    } catch (e) {
      debugPrint('Error fetching attachment bytes: $e');
      return null;
    }
  }

  Future<bool> _openWebAttachment(Map<String, dynamic> attachment) async {
    final bytes = await _fetchAttachmentBytes(attachment);
    if (bytes == null) {
      return false;
    }

    final originalName = _attachmentOriginalName(attachment);
    final mimeType = _attachmentMimeType(attachment);
    final preferInline =
        _isPdfFile(originalName) ||
        _isTextPreviewable(originalName, mimeType) ||
        (mimeType?.startsWith('image/') ?? false);

    return openBrowserFile(
      bytes: bytes,
      fileName: originalName,
      mimeType: mimeType,
      preferInline: preferInline,
    );
  }

  Future<bool> _openTextPreview(Map<String, dynamic> attachment) async {
    try {
      final localFile = await _ensureLocalAttachmentFile(
        attachment,
        announceDownload: true,
      );
      final bytes = await localFile.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      if (!mounted) return true;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _TextAttachmentViewerScreen(
            title: _attachmentDisplayName(attachment),
            content: content,
          ),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Error opening text preview: $e');
      return false;
    }
  }

  String? _mimeTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.csv')) return 'text/csv';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.zip')) return 'application/zip';
    if (lower.endsWith('.rar')) return 'application/vnd.rar';
    return null;
  }

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
        lower.endsWith('.heic')) {
      return 'image';
    }
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
        type: FileType.any,
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

    final cloudinary = CloudinaryPublic(
      _cloudName,
      _uploadPreset,
      cache: false,
    );

    for (int i = 0; i < files.length; i++) {
      try {
        final file = files[i];
        final name = file.path.split('/').last;
        final fileType = _classifyFile(name, null);
        late final Response<dynamic> savedAttachment;

        if (fileType == 'image') {
          final response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              file.path,
              resourceType: CloudinaryResourceType.Image,
              folder: 'sitesync/tasks/${widget.taskId}',
            ),
          );

          savedAttachment = await apiClient.post(
            '/tasks/${widget.taskId}/attachments',
            data: {
              'url': response.secureUrl,
              'storageProvider': 'external',
              'displayName': name,
              'originalName': name,
              'fileType': fileType,
              'mimeType': null,
              'fileSize': file.lengthSync(),
            },
          );
        } else {
          final formData = FormData.fromMap({
            'displayName': name,
            'file': await MultipartFile.fromFile(file.path, filename: name),
          });

          savedAttachment = await apiClient.post(
            '/tasks/${widget.taskId}/attachments/upload',
            data: formData,
          );
        }

        // Save a local copy so the file can be opened without downloading
        if (!kIsWeb) {
          try {
            final taskDir = await TaskAttachmentsWidget.taskDirPath(
              widget.taskId,
            );
            await Directory(taskDir).create(recursive: true);
            final attachment = Map<String, dynamic>.from(
              savedAttachment.data as Map,
            );
            final cachedPath =
                '$taskDir/${_cacheFileNameForAttachment(attachment)}';
            await file.copy(cachedPath);
          } catch (_) {}
        }

        if (mounted) {
          setState(() => _uploadProgress = (i + 1) / files.length);
        }
      } catch (e) {
        debugPrint('Error uploading file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to upload: ${files[i].path.split('/').last}',
              ),
            ),
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
    final name = _attachmentDisplayName(attachment);
    final originalName = _attachmentOriginalName(attachment);
    final mimeType = _attachmentMimeType(attachment);
    final type = attachment['file_type'] as String? ?? 'document';
    final isOfficeDocument = _isOfficeDocument(originalName);

    if (type == 'image') {
      final url = attachment['url'] as String? ?? '';
      _showImageViewer(url, name);
      return;
    }

    if (!kIsWeb &&
        _isTextPreviewable(originalName, mimeType) &&
        await _openTextPreview(attachment)) {
      return;
    }

    if (kIsWeb) {
      final opened =
          await _openWebAttachment(attachment) ||
          await _openWithBrowserViewer(attachment) ||
          await _openRemoteAttachment(attachment);
      if (!opened) {
        _showMessage('Could not open file');
      }
      return;
    }

    final opened =
        await _openWithSystemViewer(attachment) ||
        (isOfficeDocument && await _openWithBrowserViewer(attachment));

    if (!opened) {
      final url = _attachmentUrl(attachment);
      if (_isPdfFile(originalName) && _isCloudinaryAttachmentUrl(url)) {
        _showMessage(
          'This PDF is coming from an older Cloudinary upload that is returning 401. Re-upload the file after updating the app.',
          duration: const Duration(seconds: 4),
        );
        return;
      }

      final guidance = _isPdfFile(originalName)
          ? 'Could not open file. Please install a PDF viewer on this device.'
          : 'Could not open file. Please install a document viewer on this device.';
      _showMessage(guidance, duration: const Duration(seconds: 3));
    }
  }

  String _extractExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return '';
    return fileName.substring(dot); // e.g. '.pdf'
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
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
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
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
                          color: _colorForType(type).withValues(alpha: 0.1),
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        _iconForType(type),
                                        size: 20,
                                        color: _colorForType(type),
                                      ),
                                ),
                              )
                            : Icon(
                                _iconForType(type),
                                size: 20,
                                color: _colorForType(type),
                              ),
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
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _deleteAttachment(att),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red,
                            ),
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

class _TextAttachmentViewerScreen extends StatelessWidget {
  final String title;
  final String content;

  const _TextAttachmentViewerScreen({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Container(
        color: AppTheme.background,
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            content,
            style: AppTheme.body.copyWith(fontFamily: 'monospace', height: 1.5),
          ),
        ),
      ),
    );
  }
}
