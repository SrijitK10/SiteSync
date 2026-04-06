import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../services/api_client.dart';
import 'package:intl/intl.dart';

// ==========================================
// Cloudinary Configuration Constants
// ==========================================
const String cloudinaryCloudName = 'decj8mbhf';
const String cloudinaryUploadPreset = 'rupayan';


class GalleryTab extends StatefulWidget {
  final String projectId;
  final String projectName;

  const GalleryTab({super.key, required this.projectId, required this.projectName});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  List<dynamic> _images = [];
  bool _isLoading = true;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    try {
      final res = await apiClient.get('/projects/${widget.projectId}/images');
      if (mounted) {
        setState(() {
          _images = res.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load images: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
    if (images.isEmpty) return;

    // Show Dialog for caption
    final captionController = TextEditingController();
    bool dialogCanceled = true;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.background,
              title: Text('Preview (${images.length})', style: AppTheme.heading),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(images[index].path),
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'GROUP CAPTION', 
                      hint: 'Describe progress...', 
                      controller: captionController
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text('Cancel', style: TextStyle(color: Colors.red))
                ),
                TextButton(
                  onPressed: () async {
                    final List<XFile> newImgs = await _picker.pickMultiImage(imageQuality: 70);
                    if (newImgs.isNotEmpty) {
                      setDialogState(() {
                        images = newImgs;
                      });
                    }
                  },
                  child: const Text('Reselect', style: TextStyle(color: AppTheme.primary))
                ),
                AppButton(
                  text: 'Upload', 
                  onPressed: () {
                    dialogCanceled = false;
                    Navigator.pop(ctx);
                  }
                )
              ],
            );
          }
        );
      }
    );

    if (dialogCanceled) return;

    setState(() => _isUploading = true);

    try {
      // 1. Upload to Cloudinary
      if (cloudinaryCloudName == 'YOUR_CLOUD_NAME') {
        throw Exception('Cloudinary configuration missing. Please update constants in gallery_tab.dart.');
      }
      
      final String folderPath = widget.projectName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_'); // Sanitize folder name
      final cloudinary = CloudinaryPublic(cloudinaryCloudName, cloudinaryUploadPreset, cache: false);
      
      // We perform serial uploads to prevent overwhelming limits or Memory
      for (var img in images) {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(img.path, resourceType: CloudinaryResourceType.Image, folder: folderPath),
        );

        final imageUrl = response.secureUrl;

        // 2. Transmit to backend
        await apiClient.post('/projects/${widget.projectId}/images', data: {
          'url': imageUrl,
          'caption': captionController.text.trim(),
        });
      }

      // 3. Refresh list
      _fetchImages();

    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Failed: $e', style: const TextStyle(color: Colors.red))));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _shareOrDownloadImage(String url, String dateString) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/progress_$dateString.jpg';
      
      // Download to temp directory
      await Dio().download(url, savePath);
      
      // Pass downloaded file to native Share sheet
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(savePath)], 
        text: 'SiteSync Progress Image - ${widget.projectName}',
        subject: 'Project Update'
      );
    } catch (e) {
      debugPrint('Error sharing/downloading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _isUploading ? null : _pickAndUploadImage,
        child: _isUploading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.surface, strokeWidth: 2))
            : const Icon(Icons.add_a_photo, color: AppTheme.surface),
      ),
      body: _images.isEmpty
          ? Center(child: Text('No progress active images recorded.', style: AppTheme.body))
          : RefreshIndicator(
              onRefresh: _fetchImages,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  final img = _images[index];
                  final String dateString = img['date'] ?? '';
                  final dateFormatted = dateString.isNotEmpty 
                      ? DateFormat('MMM dd, yyyy').format(DateTime.parse(dateString))
                      : 'Unknown Date';
                  final String uploaderName = img['uploadedBy']?['name'] ?? 'Unknown User';

                  return Card(
                    color: AppTheme.surface,
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.network(
                          img['url'],
                          height: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (img['caption'] != null && img['caption'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(img['caption'], style: AppTheme.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('By: $uploaderName', style: AppTheme.label.copyWith(color: AppTheme.primary)),
                                        const SizedBox(height: 4),
                                        Text(dateFormatted, style: AppTheme.label),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.share, color: AppTheme.primary),
                                    tooltip: 'Share / Save Image',
                                    onPressed: () => _shareOrDownloadImage(img['url'], img['date'] ?? 'unknown'),
                                  )
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
