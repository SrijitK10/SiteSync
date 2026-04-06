import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    final File sourceFile = File(image.path);

    // Show Dialog for caption
    final captionController = TextEditingController();
    bool dialogCanceled = true;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: Text('Add Caption', style: AppTheme.heading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(sourceFile, height: 150, fit: BoxFit.cover),
              const SizedBox(height: 16),
              AppTextField(
                label: 'CAPTION', 
                hint: 'Describe progress...', 
                controller: captionController
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('Cancel', style: TextStyle(color: Colors.red))
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

    if (dialogCanceled) return;

    setState(() => _isUploading = true);

    try {
      // 1. Upload to Cloudinary
      if (cloudinaryCloudName == 'YOUR_CLOUD_NAME') {
        throw Exception('Cloudinary configuration missing. Please update constants in gallery_tab.dart.');
      }
      
      final String folderPath = widget.projectName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_'); // Sanitize folder name
      
      final cloudinary = CloudinaryPublic(cloudinaryCloudName, cloudinaryUploadPreset, cache: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(sourceFile.path, resourceType: CloudinaryResourceType.Image, folder: folderPath),
      );

      final imageUrl = response.secureUrl;

      // 2. Transmit to backend
      await apiClient.post('/projects/${widget.projectId}/images', data: {
        'url': imageUrl,
        'caption': captionController.text.trim(),
      });

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
                                  Text('By: $uploaderName', style: AppTheme.label.copyWith(color: AppTheme.primary)),
                                  Text(dateFormatted, style: AppTheme.label),
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
