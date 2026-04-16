import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../services/api_client.dart';
import '../state/auth_provider.dart';
import '../state/unread_tracker_provider.dart';
import 'package:intl/intl.dart';

const String cloudinaryCloudName = 'decj8mbhf';
const String cloudinaryUploadPreset = 'rupayan';

class GalleryTab extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  final ValueChanged<List<dynamic>>? onImagesViewed;

  const GalleryTab({
    super.key,
    required this.projectId,
    required this.projectName,
    this.onImagesViewed,
  });

  @override
  ConsumerState<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends ConsumerState<GalleryTab> {
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
      final images = List<dynamic>.from(res.data as List<dynamic>);
      if (mounted) {
        setState(() {
          _images = images;
          _isLoading = false;
        });
      }
      await _markImagesAsViewed(images);
      widget.onImagesViewed?.call(images);
    } catch (e) {
      debugPrint('Failed to load images: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markImagesAsViewed(List<dynamic> images) async {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId == null) return;

    await ref
        .read(unreadTrackerProvider.notifier)
        .markProgressVisited(
          userId: userId,
          projectId: widget.projectId,
          images: images,
        );
  }

  // Groups images by date, preserving insertion order (newest first)
  List<List<dynamic>> _groupByPost() {
    final List<List<dynamic>> posts = [];
    for (final img in _images) {
      if (posts.isEmpty) {
        posts.add([img]);
        continue;
      }

      final lastPost = posts.last;
      final lastImg = lastPost.last;

      final dt1 = DateTime.tryParse(img['date'] ?? '');
      final dt2 = DateTime.tryParse(lastImg['date'] ?? '');

      bool sameGroup = false;
      if (dt1 != null && dt2 != null && img['caption'] == lastImg['caption']) {
        if (dt1.difference(dt2).inMinutes.abs() <= 5) {
          sameGroup = true;
        }
      } else if (dt1 == null &&
          dt2 == null &&
          img['caption'] == lastImg['caption']) {
        sameGroup = true;
      }

      if (sameGroup) {
        lastPost.add(img);
      } else {
        posts.add([img]);
      }
    }
    return posts;
  }

  void _openFullscreen(List<dynamic> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenViewer(
          images: images,
          initialIndex: initialIndex,
          projectName: widget.projectName,
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
    if (images.isEmpty) return;

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
              title: Text(
                'Preview (${images.length})',
                style: AppTheme.heading,
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                      controller: captionController,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final List<XFile> newImgs = await _picker.pickMultiImage(
                      imageQuality: 70,
                    );
                    if (newImgs.isNotEmpty) {
                      setDialogState(() => images = newImgs);
                    }
                  },
                  child: Text(
                    'Reselect',
                    style: TextStyle(color: AppTheme.primary),
                  ),
                ),
                AppButton(
                  text: 'Upload',
                  onPressed: () {
                    dialogCanceled = false;
                    Navigator.pop(ctx);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) {
      captionController.dispose();
      return;
    }

    if (dialogCanceled) {
      captionController.dispose();
      return;
    }

    setState(() => _isUploading = true);

    try {
      final String folderPath = widget.projectName.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-]'),
        '_',
      );
      final cloudinary = CloudinaryPublic(
        cloudinaryCloudName,
        cloudinaryUploadPreset,
        cache: false,
      );

      for (var img in images) {
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            img.path,
            resourceType: CloudinaryResourceType.Image,
            folder: folderPath,
          ),
        );
        await apiClient.post(
          '/projects/${widget.projectId}/images',
          data: {
            'url': response.secureUrl,
            'caption': captionController.text.trim(),
          },
        );
      }

      _fetchImages();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload Failed: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      }
    } finally {
      captionController.dispose();
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _shareImages(List<dynamic> images, String caption) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing images to share...')),
      );
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final dio = Dio();
      final List<XFile> files = [];

      for (int i = 0; i < images.length; i++) {
        final savePath =
            '${tempDir.path}/share_${images[i]['date'] ?? 'img'}_$i.jpg';
        await dio.download(images[i]['url'], savePath);
        files.add(XFile(savePath));
      }

      final shareText = caption.isNotEmpty ? caption : widget.projectName;
      // ignore: deprecated_member_use
      await Share.shareXFiles(files, text: shareText, subject: shareText);
    } catch (e) {
      debugPrint('Error sharing images: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final posts = _groupByPost();

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: _isUploading ? null : _pickAndUploadImage,
        child: _isUploading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppTheme.surface,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.add_a_photo, color: AppTheme.surface),
      ),
      body: _images.isEmpty
          ? Center(
              child: Text('No progress images recorded.', style: AppTheme.body),
            )
          : RefreshIndicator(
              onRefresh: _fetchImages,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: posts.length,
                itemBuilder: (context, groupIndex) {
                  final groupImages = posts[groupIndex];
                  final rawDate = groupImages.first['date'] ?? 'Unknown';
                  final dateFormatted =
                      rawDate != 'Unknown' && rawDate.isNotEmpty
                      ? DateFormat(
                          'MMM dd, yyyy  h:mm a',
                        ).format(DateTime.parse(rawDate).toLocal())
                      : 'Unknown Date';
                  final uploaderName =
                      groupImages.first['uploadedBy']?['name'] ??
                      'Unknown User';
                  final caption =
                      groupImages.first['caption']?.toString() ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Row(
                          children: [
                            Text(
                              dateFormatted,
                              style: AppTheme.label.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '· ${groupImages.length} photo${groupImages.length > 1 ? 's' : ''}',
                              style: AppTheme.label.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _shareImages(groupImages, caption),
                              child: Icon(
                                Icons.share,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Horizontal image strip
                        SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: groupImages.length,
                            itemBuilder: (context, imgIndex) {
                              final img = groupImages[imgIndex];
                              return GestureDetector(
                                onTap: () =>
                                    _openFullscreen(groupImages, imgIndex),
                                child: Container(
                                  width: 160,
                                  margin: EdgeInsets.only(
                                    right: imgIndex < groupImages.length - 1
                                        ? 8
                                        : 0,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      img['url'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Caption + uploader
                        if (caption.isNotEmpty)
                          Text(
                            caption,
                            style: AppTheme.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          'By $uploaderName',
                          style: AppTheme.label.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ─── Full-Screen Viewer ───────────────────────────────────────────────────────

class _FullscreenViewer extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;
  final String projectName;

  const _FullscreenViewer({
    required this.images,
    required this.initialIndex,
    required this.projectName,
  });

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareImage(
    String url,
    String dateString,
    String caption,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/progress_$dateString.jpg';
      await Dio().download(url, savePath);
      final shareText = caption.isNotEmpty ? caption : widget.projectName;
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(savePath)],
        text: shareText,
        subject: shareText,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.images[_currentIndex];
    final dateString = img['date'] ?? '';
    final dateFormatted = dateString.isNotEmpty
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(dateString))
        : 'Unknown Date';
    final caption = img['caption']?.toString() ?? '';
    final uploader = img['uploadedBy']?['name'] ?? 'Unknown';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareImage(img['url'], dateString, caption),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Swipeable + zoomable images
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    widget.images[index]['url'],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 60,
                    ),
                  ),
                ),
              );
            },
          ),
          // Bottom info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (caption.isNotEmpty)
                    Text(
                      caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '$uploader · $dateFormatted',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
