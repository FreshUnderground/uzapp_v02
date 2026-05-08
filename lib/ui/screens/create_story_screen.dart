import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/story_repository.dart';
import '../../data/repositories/shop_repository.dart';
import 'package:drift/drift.dart' hide Column;
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
  final bool isArrivage;
  const CreateStoryScreen({
    super.key,
    required this.shopId,
    this.isArrivage = false,
  });

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
    if (widget.isArrivage) {
      // Multi-image selection for arrivages
      final List<XFile> files = await _picker.pickMultiImage();
      if (files.isEmpty) return;

      final List<_PendingMedia> newItems = [];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        newItems.add(
          _PendingMedia(file: file, bytes: bytes, mediaType: 'image'),
        );
      }
      setState(() {
        _selectedMedia.addAll(newItems);
      });
    } else {
      // Single selection for regular stories
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
      if (widget.isArrivage) {
        // Append for arrivages
        _selectedMedia.add(
          _PendingMedia(file: file, bytes: bytes, mediaType: 'video'),
        );
      } else {
        // Replace for regular stories
        _selectedMedia.clear();
        _selectedMedia.add(
          _PendingMedia(file: file, bytes: bytes, mediaType: 'video'),
        );
      }
    });
  }

  void _removeMedia() {
    setState(() {
      _selectedMedia.clear();
    });
  }

  void _removeMediaAt(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
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

      // 1. Upload all media files
      final List<String> remoteUrls = [];
      final List<String> mediaTypes = [];

      for (var i = 0; i < _selectedMedia.length; i++) {
        final media = _selectedMedia[i];
        setState(() {
          _uploadMessage =
              'Envoi ${i + 1}/${_selectedMedia.length} (${ImageCompressUtils.getFileSizeString(media.bytes.length)})...';
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
            'story_${DateTime.now().millisecondsSinceEpoch}_$i.${media.file.name.split('.').last}';

        final remoteUrl = await apiService.uploadFile(
          bytesToUpload,
          fileName,
          folder: 'stories',
          timeout: const Duration(seconds: 30),
        );

        if (remoteUrl == null) {
          throw Exception('Échec de l\'upload du média ${i + 1}');
        }

        remoteUrls.add(remoteUrl);
        mediaTypes.add(media.mediaType);
      }

      // 2. Create story (with optional multi-media for arrivages)
      final nowUtc = DateTime.now().toUtc();
      final expiresAt = widget.isArrivage
          ? nowUtc.add(StoryRepository.arrivageExpiry)
          : nowUtc.add(StoryRepository.storyExpiry);

      if (widget.isArrivage && remoteUrls.length > 1) {
        // Arrivage with multiple media → use addStoryWithMedia
        final mediaItems = <StoryMediaCompanion>[];
        for (var i = 1; i < remoteUrls.length; i++) {
          mediaItems.add(
            StoryMediaCompanion.insert(
              storyId: 0, // placeholder, will be set by addStoryWithMedia
              mediaUrl: CryptoUtils.encrypt(remoteUrls[i]),
              mediaType: Value(mediaTypes[i]),
              sortOrder: Value(i),
            ),
          );
        }
        await storyRepo.addStoryWithMedia(
          StoriesCompanion.insert(
            shopId: widget.shopId,
            mediaUrl: CryptoUtils.encrypt(remoteUrls.first),
            mediaType: mediaTypes.first,
            isArrivage: Value(widget.isArrivage),
            expiresAt: expiresAt,
          ),
          mediaItems,
        );
      } else {
        // Single media story (or regular story)
        await storyRepo.addStory(
          StoriesCompanion.insert(
            shopId: widget.shopId,
            mediaUrl: CryptoUtils.encrypt(remoteUrls.first),
            mediaType: mediaTypes.first,
            isArrivage: Value(widget.isArrivage),
            expiresAt: expiresAt,
          ),
        );
      }

      // 3. Queue for remote sync
      if (!mounted) return;
      final shop = await shopRepo.getShopById(widget.shopId);
      final remoteShopId = int.tryParse(shop?.remoteId ?? '') ?? widget.shopId;
      final syncPayload = <String, dynamic>{
        'shop_id': remoteShopId,
        'media_url': remoteUrls.first,
        'media_type': mediaTypes.first,
        'is_arrivage': widget.isArrivage ? 1 : 0,
        'expires_at': expiresAt.toIso8601String(),
      };
      if (remoteUrls.length > 1) {
        syncPayload['media'] = List.generate(
          remoteUrls.length - 1,
          (i) => {
            'media_url': remoteUrls[i + 1],
            'media_type': mediaTypes[i + 1],
            'sort_order': i + 1,
          },
        );
      }
      await syncService.addToQueue('CREATE', 'stories', syncPayload);

      // Trigger immediate push so the story appears on the server
      syncService.forcePush();

      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.isArrivage
                  ? 'Arrivage publié avec succès !'
                  : 'Story publiée avec succès !',
            ),
          ),
        );
        navigator.pop(context);
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
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
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
      appBar: AppBar(
        title: Text(
          widget.isArrivage ? 'Nouvel Arrivage' : 'Publier une Story',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isArrivage
                  ? 'Annoncez les nouvelles arrivées de votre boutique'
                  : 'Partagez une nouveauté de votre boutique',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isArrivage
                  ? 'Les arrivages sont visibles pendant 4 jours par tous les utilisateurs.'
                  : 'Les stories sont visibles pendant 24 heures par tous les utilisateurs.',
              style: const TextStyle(color: Colors.grey),
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
                  '${_selectedMedia.length} média(s) sélectionné(s)',
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
                    : Text(
                        widget.isArrivage
                            ? 'PUBLIER L\'ARRIVAGE'
                            : 'PUBLIER LA STORY',
                        style: const TextStyle(
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
              label: const Text('Effacer tout'),
              style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_selectedMedia.length, (index) {
            final media = _selectedMedia[index];
            final isSingle = _selectedMedia.length == 1;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: isSingle
                      ? double.infinity
                      : (MediaQuery.of(context).size.width - 72) / 2,
                  height: isSingle ? 240 : 180,
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
                // Remove button for individual item
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeMediaAt(index),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
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
            );
          }),
        ),
      ],
    );
  }
}
