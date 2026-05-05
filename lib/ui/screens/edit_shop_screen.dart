import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import 'dart:typed_data';

import '../components/responsive_layout.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/api_service.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/shop_repository.dart';
import '../../core/utils/picker_utils.dart';
import '../../core/utils/crypto_utils.dart';
import '../../data/repositories/location_data.dart';
import '../../data/services/sync_service.dart';

class EditShopScreen extends StatefulWidget {
  final Shop shop;
  const EditShopScreen({super.key, required this.shop});

  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _addressController;
  late TextEditingController _whatsappController;
  late TextEditingController _fbController;
  late TextEditingController _ttController;
  late TextEditingController _igController;
  late TextEditingController _logoController;
  late TextEditingController _bannerController;
  late TextEditingController _bannerTextController;
  late TextEditingController _videoController;
  Uint8List? _previewBytes;
  Uint8List? _bannerBytes;
  Uint8List? _videoBytes;
  String? _selectedCity;
  String? _selectedCommune;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shop.name);
    _descController = TextEditingController(text: widget.shop.description);
    _addressController = TextEditingController(text: widget.shop.address);
    _whatsappController = TextEditingController(text: widget.shop.whatsapp);
    _fbController = TextEditingController(text: widget.shop.facebookUrl);
    _ttController = TextEditingController(text: widget.shop.tiktokUrl);
    _igController = TextEditingController(text: widget.shop.instagramUrl);

    final decryptedLogo = CryptoUtils.decrypt(widget.shop.logoUrl ?? '');
    _logoController = TextEditingController(text: decryptedLogo);
    final decryptedBanner = CryptoUtils.decrypt(widget.shop.bannerUrl ?? '');
    _bannerController = TextEditingController(text: decryptedBanner);
    _bannerTextController = TextEditingController(text: widget.shop.bannerText);
    final decryptedVideo = CryptoUtils.decrypt(widget.shop.videoUrl ?? '');
    _videoController = TextEditingController(text: decryptedVideo);

    // Pre-populate city and commune from existing shop data
    _selectedCity = widget.shop.city;
    _selectedCommune = widget.shop.commune;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _whatsappController.dispose();
    _fbController.dispose();
    _ttController.dispose();
    _igController.dispose();
    _logoController.dispose();
    _bannerController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final bytes = await PickerUtils.pickImage(context);
    if (bytes != null) {
      final base64String = base64Encode(bytes);
      setState(() {
        _previewBytes = bytes;
        _logoController.text = "data:image/png;base64,$base64String";
      });
    }
  }

  Future<void> _pickVideo() async {
    final bytes = await PickerUtils.pickVideo(context);
    if (bytes != null) {
      setState(() {
        _videoBytes = bytes;
        _videoController.text =
            "Vidéo sélectionnée (${(bytes.length / 1024 / 1024).toStringAsFixed(1)} MB)";
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    _showLoadingDialog();

    try {
      final apiService = context.read<ApiService>();
      final shopRepo = context.read<ShopRepository>();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      String finalLogoUrl = _logoController.text.trim();
      if (_previewBytes != null) {
        final fileName = "shop_logo_update_${widget.shop.id}.png";
        final uploadedUrl = await apiService.uploadFile(
          _previewBytes!,
          fileName,
        );
        if (uploadedUrl != null) finalLogoUrl = uploadedUrl;
      }

      String finalBannerUrl = _bannerController.text;
      if (_bannerBytes != null) {
        final fileName = "shop_banner_update_${widget.shop.id}.png";
        final uploadedUrl = await apiService.uploadFile(
          _bannerBytes!,
          fileName,
          folder: 'boutiques',
        );
        if (uploadedUrl != null) finalBannerUrl = uploadedUrl;
      }

      String finalVideoUrl = _videoController.text;
      if (_videoBytes != null) {
        final fileName = "shop_video_update_${widget.shop.id}.mp4";
        final uploadedUrl = await apiService.uploadFile(
          _videoBytes!,
          fileName,
          folder: 'boutiques/videos',
        );
        if (uploadedUrl != null) finalVideoUrl = uploadedUrl;
      }

      final updatedShop = ShopsCompanion(
        id: drift.Value(widget.shop.id),
        name: drift.Value(_nameController.text),
        description: drift.Value(_descController.text),
        address: drift.Value(_addressController.text),
        whatsapp: drift.Value(_whatsappController.text),
        facebookUrl: drift.Value(_fbController.text),
        tiktokUrl: drift.Value(_ttController.text),
        instagramUrl: drift.Value(_igController.text),
        logoUrl: drift.Value(CryptoUtils.encrypt(finalLogoUrl)),
        bannerUrl: drift.Value(CryptoUtils.encrypt(finalBannerUrl)),
        videoUrl: drift.Value(CryptoUtils.encrypt(finalVideoUrl)),
        bannerText: drift.Value(_bannerTextController.text),
        city: drift.Value(_selectedCity),
        commune: drift.Value(_selectedCommune),
        updatedAt: drift.Value(DateTime.now()),
      );

      await shopRepo.updateShop(updatedShop);

      // Queue for remote sync
      if (mounted) {
        try {
          final syncService = context.read<SyncService>();
          await syncService.addToQueue('UPDATE', 'shops', {
            'id': widget.shop.id,
            'name': _nameController.text,
            'description': _descController.text,
            'address': _addressController.text,
            'whatsapp': _whatsappController.text,
            'facebook_url': _fbController.text,
            'tiktok_url': _ttController.text,
            'instagram_url': _igController.text,
            'logo_url': finalLogoUrl,
            'banner_url': finalBannerUrl,
            'video_url': finalVideoUrl,
            'banner_text': _bannerTextController.text,
            'city': _selectedCity,
            'commune': _selectedCommune,
          });
          syncService.forcePush();
        } catch (_) {
          // Sync queue failure should not block the user
        }
      }

      if (!mounted) return;
      navigator.pop(); // Close loading dialog
      messenger.showSnackBar(
        const SnackBar(content: Text('Profil mis à jour')),
      );
      navigator.pop();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text("Enregistrement..."),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier ma Boutique')),
      body: ResponsiveLayout(
        mobile: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildForm(),
        ),
        desktop: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: _buildForm(isDesktop: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm({bool isDesktop = false}) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildLogoSection(),
                      const SizedBox(height: 24),
                      _buildGeneralInfo(),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(child: _buildSocialInfo()),
              ],
            )
          else ...[
            _buildLogoSection(),
            const SizedBox(height: 24),
            _buildGeneralInfo(),
            const SizedBox(height: 24),
            _buildVideoSection(),
            const SizedBox(height: 24),
            _buildSocialInfo(),
          ],
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
              backgroundColor: UzaColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer les modifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        const Text('Logo', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _previewBytes != null
                ? MemoryImage(_previewBytes!)
                : null,
            child: _previewBytes == null ? const Icon(Icons.add_a_photo) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralInfo() {
    final cities = LocationData.cities;
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        TextFormField(
          controller: _descController,
          decoration: const InputDecoration(labelText: 'Description'),
          maxLines: 3,
        ),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: 'Adresse'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          decoration: const InputDecoration(
            labelText: 'Ville',
            prefixIcon: Icon(Icons.location_city),
          ),
          items: cities.keys.map((city) {
            return DropdownMenuItem(value: city, child: Text(city));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCity = value;
              _selectedCommune = null;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedCity ?? 'none'),
          value: _selectedCommune,
          decoration: const InputDecoration(
            labelText: 'Commune',
            prefixIcon: Icon(Icons.place),
          ),
          items: _selectedCity != null
              ? cities[_selectedCity]!.map((commune) {
                  return DropdownMenuItem(value: commune, child: Text(commune));
                }).toList()
              : [],
          onChanged: (value) {
            setState(() => _selectedCommune = value);
          },
        ),
      ],
    );
  }

  Widget _buildSocialInfo() {
    return Column(
      children: [
        _socialField(_whatsappController, 'WhatsApp', Icons.chat),
        _socialField(_fbController, 'Facebook', Icons.facebook),
        _socialField(_igController, 'Instagram', Icons.camera),
        _socialField(_ttController, 'TikTok', Icons.music_note),
      ],
    );
  }

  Widget _buildVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vidéo de Présentation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickVideo,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.videocam,
                  color:
                      _videoBytes != null ||
                          _videoController.text.startsWith('http')
                      ? UzaColors.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _videoController.text.isEmpty
                        ? 'Ajouter une vidéo de présentation'
                        : _videoController.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_videoController.text.isNotEmpty)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}
