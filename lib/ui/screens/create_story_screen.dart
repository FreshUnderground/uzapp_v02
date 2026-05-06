import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/story_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/local/uza_database.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_compress_utils.dart';
import '../../data/services/sync_service.dart';

/// Represents a selected media item before upload.
class _PendingMedia {
  final XFile file;
  final Uint8List bytes;
  final String mediaType; // 'image' or 'video'

  _PendingMedia({
    required this.file,
    required this.bytes,
    required this.mediaType,
  });
}

class CreateStoryScreen extends StatefulWidget {
  final int shopId;
  const CreateStoryScreen({super.key, required this.shopId});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _picker = ImagePicker();
  final List<_PendingMedia> _selectedMedia = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _uploadMessage;

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _selectedMedia.clear();
      _selectedMedia.add(
        _PendingMedia(file: file, bytes: bytes, mediaType: 'image'),
      );
    });
  }

  Future<void> _pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    const maxVideoSize = 20 * 1024 * 1024; // 20MB
    if (bytes.length > maxVideoSize) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La vidéo est trop volumineuse (max 20 Mo). Utilisez une vidéo plus courte.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _selectedMedia.clear();
      _selectedMedia.add(
        _PendingMedia(file: file, bytes: bytes, mediaType: 'video'),
      );
    });
  }

  void _removeMedia() {
    setState(() {
      _selectedMedia.clear();
    });
  }

  Future<void> _submit() async {
    if (_isUploading) return;
    if (_selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un média')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
      _uploadMessage = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final storyRepo = context.read<StoryRepository>();
      final syncService = context.read<SyncService>();
      final shopRepo = context.read<ShopRepository>();

      // 1. Upload the single media file
      final media = _selectedMedia.first;
      setState(() {
        _uploadMessage =
            'Envoi (${ImageCompressUtils.getFileSizeString(media.bytes.length)})...';
      });

      Uint8List bytesToUpload = media.bytes;

      // Compress images (skip for videos)
      if (media.mediaType == 'image') {
        final compressed = await ImageCompressUtils.compressImage(
          media.bytes,
          maxWidth: 1080,
          quality: 70,
        );
        if (compressed != null) {
          bytesToUpload = compressed;
        }
      }

      final fileName =
          'story_${DateTime.now().millisecondsSinceEpoch}.${media.file.name.split('.').last}';

      final remoteUrl = await apiService.uploadFile(
        bytesToUpload,
        fileName,
        folder: 'stories',
        timeout: const Duration(seconds: 30),
      );

      if (remoteUrl == null) {
        throw Exception('Échec de l\'upload du média');
      }

      // 2. Create story (single media, no story_media children)
      final nowUtc = DateTime.now().toUtc();
      final expiresAt = nowUtc.add(StoryRepository.storyExpiry);

      final storyId = await storyRepo.addStory(
        StoriesCompanion.insert(
          shopId: widget.shopId,
          mediaUrl: CryptoUtils.encrypt(remoteUrl),
          mediaType: media.mediaType,
          expiresAt: expiresAt,
        ),
      );

      // 3. Queue for remote sync
      if (!mounted) return;
      final shop = await shopRepo.getShopById(widget.shopId);
      await syncService.addToQueue('CREATE', 'stories', {
        'id': storyId,
        'shop_id': widget.shopId,
        'shop_name': shop?.name ?? 'Boutique',
        'media_url': remoteUrl,
        'media_type': media.mediaType,
        'created_at': nowUtc.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story publiée avec succès !')),
        );
        Navigator.pop(context);
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('La connexion est lente. Réessayer?'),
            action: SnackBarAction(label: 'RÉESSAYER', onPressed: _submit),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
          _uploadMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publier une Story')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Partagez une nouveauté de votre boutique',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les stories sont visibles pendant 24 heures par tous les utilisateurs.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Action buttons for picking media
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UzaColors.primary,
                      side: const BorderSide(color: UzaColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Vidéo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UzaColors.primary,
                      side: const BorderSide(color: UzaColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedMedia.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '1 média sélectionné',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            const SizedBox(height: 16),

            // Preview grid of selected media
            if (_selectedMedia.isNotEmpty)
              _buildMediaPreviewGrid()
            else
              _buildEmptyPicker(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _selectedMedia.isEmpty
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: UzaColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          if (_uploadMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _uploadMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      )
                    : const Text(
                        'PUBLIER LA STORY',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Cliquez pour ajouter une photo ou vidéo',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreviewGrid() {
    final media = _selectedMedia.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aperçu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            TextButton.icon(
              onPressed: _removeMedia,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Effacer'),
              style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200],
              ),
              clipBehavior: Clip.antiAlias,
              child: media.mediaType == 'image'
                  ? Image.memory(media.bytes, fit: BoxFit.cover)
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam,
                                  color: UzaColors.primary,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Vidéo',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            // Remove button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _removeMedia,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
            // Video play icon indicator
            if (media.mediaType == 'video')
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: UzaColors.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
