import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import 'package:provider/provider.dart';
import '../../core/utils/picker_utils.dart';
import '../../data/repositories/story_repository.dart';
import '../../data/repositories/shop_repository.dart';
import 'package:drift/drift.dart' hide Column;
import '../../data/local/uza_database.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/utils/image_prepare_utils.dart';
import '../../data/services/sync_service.dart';

/// Represents a selected media item before upload.
class _PendingMedia {
  final Uint8List bytes;
  final String fileName;
  final String mediaType; // 'image' or 'video'

  _PendingMedia({
    required this.bytes,
    required this.fileName,
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
  final List<_PendingMedia> _selectedMedia = [];
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isPickingMedia = false;
  String? _uploadMessage;

  Future<void> _pickImage() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);
    try {
      if (widget.isArrivage) {
        final images = await PickerUtils.pickMultipleImages(context);
        if (images.isEmpty) return;

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newItems = images.asMap().entries.map((entry) {
          return _PendingMedia(
            bytes: entry.value,
            fileName: 'arrivage_${timestamp}_${entry.key}.jpg',
            mediaType: 'image',
          );
        }).toList();
        setState(() => _selectedMedia.addAll(newItems));
      } else {
        final bytes = await PickerUtils.pickImage(context);
        if (bytes == null) return;

        setState(() {
          _selectedMedia
            ..clear()
            ..add(
              _PendingMedia(
                bytes: bytes,
                fileName:
                    'story_${DateTime.now().millisecondsSinceEpoch}.jpg',
                mediaType: 'image',
              ),
            );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trf(context, 'error_with_message', {'message': '$e'})),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingMedia = false);
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);
    try {
      final picked = await PickerUtils.pickVideo(context);
      if (picked == null) return;

      const maxVideoSize = 20 * 1024 * 1024; // 20MB
      if (picked.bytes.length > maxVideoSize) {
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

      final prefix = widget.isArrivage ? 'arrivage' : 'story';
      final media = _PendingMedia(
        bytes: picked.bytes,
        fileName: picked.fileName.contains('.')
            ? picked.fileName
            : '${prefix}_${DateTime.now().millisecondsSinceEpoch}.mp4',
        mediaType: 'video',
      );

      setState(() {
        if (widget.isArrivage) {
          _selectedMedia.add(media);
        } else {
          _selectedMedia
            ..clear()
            ..add(media);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trf(context, 'error_with_message', {'message': '$e'})),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingMedia = false);
      }
    }
  }

  Future<void> _showMediaSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: UzaColors.primary),
                title: Text(widget.isArrivage ? 'Ajouter des photos' : 'Choisir une photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: UzaColors.primary),
                title: Text(widget.isArrivage ? 'Ajouter une vidéo' : 'Choisir une vidéo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
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

  String _uploadFileName(_PendingMedia media, int index) {
    if (media.fileName.isNotEmpty) return media.fileName;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (media.mediaType == 'video') {
      return 'story_${timestamp}_$index.mp4';
    }
    return 'story_${timestamp}_$index.jpg';
  }

  Future<void> _submit() async {
    if (_isUploading) return;
    if (_selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'select_media'))),
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

      // 1. Prepare then upload all media in parallel
      final preparedItems = <({Uint8List bytes, String fileName, String mediaType})>[];
      for (var i = 0; i < _selectedMedia.length; i++) {
        final media = _selectedMedia[i];
        Uint8List bytesToUpload = media.bytes;
        String fileName = _uploadFileName(media, i);

        if (media.mediaType == 'image') {
          final prepared = await ImagePrepareUtils.prepareForUpload(
            media.bytes,
            maxWidth: 1080,
            quality: 70,
            prefix: widget.isArrivage ? 'arrivage' : 'story',
          );
          bytesToUpload = await ImagePrepareUtils.ensureUploadSize(
            prepared.bytes,
          );
          fileName = prepared.fileName;
          if (bytesToUpload.length > ImagePrepareUtils.maxImageUploadBytes) {
            throw Exception(
              'Image ${i + 1} trop volumineuse (max 5 Mo). '
              'Choisissez une photo plus petite.',
            );
          }
        }
        preparedItems.add((
          bytes: bytesToUpload,
          fileName: fileName,
          mediaType: media.mediaType,
        ));
      }

      setState(() {
        _uploadMessage = 'Envoi 0/${preparedItems.length}…';
      });

      var completed = 0;
      final uploaded = await Future.wait(
        List.generate(preparedItems.length, (i) async {
          final item = preparedItems[i];
          final remoteUrl = await apiService.uploadFileOrThrow(
            item.bytes,
            item.fileName,
            folder: 'stories',
            timeout: item.mediaType == 'video'
                ? const Duration(seconds: 120)
                : const Duration(seconds: 60),
          );
          completed++;
          if (mounted) {
            setState(() {
              _uploadMessage =
                  'Envoi $completed/${preparedItems.length}…';
            });
          }
          return (url: remoteUrl, mediaType: item.mediaType);
        }),
      );

      final remoteUrls = uploaded.map((e) => e.url).toList();
      final mediaTypes = uploaded.map((e) => e.mediaType).toList();

      // 2. Create story (with optional multi-media for arrivages)
      final nowUtc = DateTime.now().toUtc();
      final expiresAt = widget.isArrivage
          ? nowUtc.add(StoryRepository.arrivageExpiry)
          : nowUtc.add(StoryRepository.storyExpiry);

      late final int localStoryId;
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
        localStoryId = await storyRepo.addStoryWithMedia(
          StoriesCompanion.insert(
            shopId: widget.shopId,
            mediaUrl: CryptoUtils.encrypt(remoteUrls.first),
            mediaType: mediaTypes.first,
            isArrivage: Value(widget.isArrivage),
            expiresAt: expiresAt,
          ),
          mediaItems,
        );
      } else if (widget.isArrivage) {
        // Single-image arrivage — must use addStoryWithMedia so isArrivage stays true
        localStoryId = await storyRepo.addStoryWithMedia(
          StoriesCompanion.insert(
            shopId: widget.shopId,
            mediaUrl: CryptoUtils.encrypt(remoteUrls.first),
            mediaType: mediaTypes.first,
            expiresAt: expiresAt,
          ),
          const [],
        );
      } else {
        // Single media regular story (24h)
        localStoryId = await storyRepo.addStory(
          StoriesCompanion.insert(
            shopId: widget.shopId,
            mediaUrl: CryptoUtils.encrypt(remoteUrls.first),
            mediaType: mediaTypes.first,
            expiresAt: expiresAt,
          ),
        );
      }

      // 3. Queue for remote sync
      if (!mounted) return;
      final shop = await shopRepo.getShopById(widget.shopId);
      final remoteShopId = int.tryParse(shop?.remoteId ?? '') ?? widget.shopId;
      final syncPayload = <String, dynamic>{
        'local_id': localStoryId,
        'local_shop_id': widget.shopId,
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
      unawaited(syncService.forcePush());

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
            content: Text(tr(context, 'slow_connection_retry')),
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
        final msg = e.toString().replaceAll('Exception: ', '');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(msg),
            action: SnackBarAction(label: 'RÉESSAYER', onPressed: _submit),
            duration: const Duration(seconds: 10),
          ),
        );
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
                    onPressed: _isLoading || _isPickingMedia ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(tr(context, 'photo_label')),
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
                    onPressed: _isLoading || _isPickingMedia ? null : _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: Text(tr(context, 'video')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UzaColors.primary,
                      side: const BorderSide(color: UzaColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (_isPickingMedia)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isArrivage
                          ? 'Chargement des médias...'
                          : 'Chargement du média...',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
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
                onPressed: _isLoading || _isPickingMedia || _selectedMedia.isEmpty
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
      onTap: _isPickingMedia ? null : _showMediaSourceSheet,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 36, color: Colors.grey[400]),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(tr(context, 'or_label'), style: TextStyle(color: Colors.grey[500])),
                ),
                Icon(Icons.videocam_outlined, size: 36, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Photo ou vidéo — touchez pour choisir',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
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
              label: Text(tr(context, 'clear_all_media')),
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
                      ? Image.memory(
                          media.bytes,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          cacheWidth: 1080,
                        )
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
