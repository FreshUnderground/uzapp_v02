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

class CreateStoryScreen extends StatefulWidget {
  final int shopId;
  const CreateStoryScreen({super.key, required this.shopId});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _picker = ImagePicker();
  XFile? _selectedFile;
  Uint8List? _fileBytes;

  String _mediaType = 'image';
  bool _isLoading = false;
  bool _isUploading = false;
  String? _uploadMessage;

  Future<void> _pickMedia() async {
    final XFile? file = _mediaType == 'image'
        ? await _picker.pickImage(source: ImageSource.gallery)
        : await _picker.pickVideo(source: ImageSource.gallery);

    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedFile = file;
        _fileBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (_isUploading) return; // Prevent double submission
    if (_selectedFile == null || _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un média')),
      );
      return;
    }

    // Warn if video is too large (> 20MB)
    const maxVideoSize = 20 * 1024 * 1024; // 20MB
    if (_mediaType == 'video' && _fileBytes!.length > maxVideoSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La vidéo est trop volumineuse. Utilisez une vidéo plus courte.',
          ),
        ),
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

      // 1. Compress image before upload (skip for videos)
      Uint8List bytesToUpload = _fileBytes!;
      if (_mediaType == 'image') {
        final compressed = await ImageCompressUtils.compressImage(
          _fileBytes!,
          maxWidth: 1080,
          quality: 70,
        );
        if (compressed != null) {
          bytesToUpload = compressed;
        }
      }

      final fileName =
          'story_${DateTime.now().millisecondsSinceEpoch}.${_selectedFile!.name.split('.').last}';

      // Show upload progress with file size
      setState(() {
        _uploadMessage =
            'Envoi de ${ImageCompressUtils.getFileSizeString(bytesToUpload.length)}...';
      });

      // Upload to server with 30s timeout
      final remoteUrl = await apiService.uploadFile(
        bytesToUpload,
        fileName,
        folder: 'stories',
        timeout: const Duration(seconds: 30),
      );

      if (remoteUrl == null) {
        throw Exception('Échec de l\'upload sur le serveur');
      }

      // 2. Save to local DB (Encrypted)
      final storyId = await storyRepo.addStory(
        StoriesCompanion.insert(
          shopId: widget.shopId,
          mediaUrl: CryptoUtils.encrypt(remoteUrl),
          mediaType: _mediaType,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        ),
      );

      // 3. Queue for remote sync
      if (!mounted) return;
      final syncService = context.read<SyncService>();
      final shopRepo = context.read<ShopRepository>();
      final shop = await shopRepo.getShopById(widget.shopId);
      final nowUtc = DateTime.now().toUtc();
      await syncService.addToQueue('CREATE', 'stories', {
        'id': storyId,
        'shop_id': widget.shopId,
        'shop_name': shop?.name ?? 'Boutique',
        'media_url': remoteUrl,
        'media_type': _mediaType,
        'created_at': nowUtc.toIso8601String(),
        'expires_at': nowUtc.add(const Duration(hours: 24)).toIso8601String(),
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
              'Partagez un moment de votre boutique',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les stories sont visibles pendant 24 heures par tous les utilisateurs.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Text(
              'Type de média',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'image',
                  groupValue: _mediaType,
                  onChanged: (v) => setState(() {
                    _mediaType = v!;
                    _selectedFile = null;
                    _fileBytes = null;
                  }),
                  activeColor: UzaColors.primary,
                ),
                const Text('Image'),
                const SizedBox(width: 24),
                Radio<String>(
                  value: 'video',
                  groupValue: _mediaType,
                  onChanged: (v) => setState(() {
                    _mediaType = v!;
                    _selectedFile = null;
                    _fileBytes = null;
                  }),
                  activeColor: UzaColors.primary,
                ),
                const Text('Vidéo'),
              ],
            ),
            const SizedBox(height: 24),

            // Preview / Picker Area
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _fileBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _mediaType == 'image'
                            ? Image.memory(_fileBytes!, fit: BoxFit.cover)
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.videocam,
                                      size: 64,
                                      color: UzaColors.primary,
                                    ),
                                    Text('Vidéo sélectionnée'),
                                  ],
                                ),
                              ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Cliquez pour ajouter une ${_mediaType == 'image' ? 'photo' : 'vidéo'}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading || _selectedFile == null ? null : _submit,
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
}
