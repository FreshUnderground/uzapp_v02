import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../components/modern_card.dart';
import '../components/tap_animator.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/image_compress_utils.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/shop_repository.dart';
import '../../core/utils/crypto_utils.dart';
import '../../data/services/sync_service.dart';
import 'auth/verification_screen.dart';

const Map<String, List<String>> cities = {
  'Butembo': ['Butembo', 'Vulamba', 'Kimemi', 'Mususa', 'vulengera'],
  'Beni': ['Beni', 'Mulekera', 'Beu', 'Ruwenzori'],
  'Goma': ['Goma', 'Karisimbi'],
  'Bukavu': ['Ibanda', 'Kadutu', 'Bagira'],
  'Bunia': ['Bunia', 'Nyakasanza', 'Shari', 'Mbogi', 'Rwambuzi'],
  'Kinshasa': [
    'Gombe',
    'Lingwala',
    'Barumbu',
    'Kinshasa',
    'Kintambo',
    'Bandalungwa',
    'Ngaliema',
    'Mont-Ngafula',
    'Selembao',
    'Bumbu',
    'Makala',
    'Ngiri-Ngiri',
    'Kalamu',
    'Lemba',
    'Limete',
    'Matete',
    'Ndjili',
    'Kimbanseke',
    'Masina',
    'Nsele',
    'Maluku',
  ],
  'Lubumbashi': [
    'Lubumbashi',
    'Kenya',
    'Kamalondo',
    'Kampemba',
    'Katuba',
    'Ruashi',
    'Annexe',
  ],
  'Mbuji-Mayi': ['Kanshi', 'Dibindi'],
  'Kisangani': [
    'Makiso',
    'Tshopo',
    'Mangobo',
    'Kabondo',
    'Kisangani',
    'Lubunga',
  ],
};

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _youtubeController = TextEditingController();

  ShopType _selectedType = ShopType.retail;
  String? _selectedCity;
  String? _selectedCommune;

  Uint8List? _logoPreviewBytes;
  String? _logoUrl;

  int _currentStep = 0;
  bool _isGoingForward = true;

  final List<String> _stepLabels = [
    'Ta boutique',
    'Contact',
    'À propos',
    'Localisation',
    'Logo',
    'Aperçu',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      final phone = authService.user?.phoneNumber ?? '';
      if (phone.isNotEmpty) {
        _phoneController.text = phone;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _descriptionController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(ImageSource source) async {
    Navigator.pop(context); // close bottom sheet
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final compressed = await ImageCompressUtils.compressImage(bytes);
      setState(() {
        _logoPreviewBytes = compressed ?? bytes;
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: UzaColors.primary),
                title: const Text('Prendre une photo'),
                onTap: () => _pickLogo(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: UzaColors.primary,
                ),
                title: const Text('Choisir dans la galerie'),
                onTap: () => _pickLogo(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().length < 3) return false;
        return true;
      case 1:
        final phone = _phoneController.text.trim();
        if (phone.isEmpty || phone.length < 9) return false;
        return true;
      case 2:
        return true; // description & social links optional
      case 3:
        if (_selectedCity == null || _selectedCommune == null) return false;
        return true;
      case 4:
        return true; // logo optional
      case 5:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) {
      _shakeCurrentStep();
      return;
    }
    if (_currentStep < 5) {
      setState(() {
        _isGoingForward = true;
        _currentStep++;
      });
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _isGoingForward = false;
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _shakeCurrentStep() {
    // Simple visual feedback via SnackBar
    String message;
    switch (_currentStep) {
      case 0:
        message = 'Le nom doit faire au moins 3 caractères';
        break;
      case 1:
        message = 'Veuillez entrer un numéro de téléphone valide';
        break;
      case 3:
        message = 'Veuillez sélectionner une ville et une commune';
        break;
      default:
        message = 'Veuillez remplir tous les champs';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submit() async {
    _showLoadingDialog();

    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      final shopRepo = context.read<ShopRepository>();
      final userId = authService.user?.uid;

      String finalLogoUrl = _logoUrl ?? '';

      if (_logoPreviewBytes != null) {
        final fileName =
            "shop_logo_${DateTime.now().millisecondsSinceEpoch}.png";
        final uploadedUrl = await apiService.uploadFile(
          _logoPreviewBytes!,
          fileName,
        );

        if (!mounted) return;

        if (uploadedUrl != null) {
          finalLogoUrl = uploadedUrl;
        } else {
          throw Exception(
            'Échec du téléchargement de l\'image sur le serveur.',
          );
        }
      }

      final encryptedLogo = finalLogoUrl.isNotEmpty
          ? CryptoUtils.encrypt(finalLogoUrl)
          : '';

      if (userId == null) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Vous devez être connecté pour créer une boutique.',
              ),
            ),
          );
        }
        return;
      }

      // Pre-check: Check if shop already exists on server
      try {
        if (!mounted) return;
        final apiService = context.read<ApiService>();
        final shops = await apiService.fetchShops();
        final alreadyExists = shops.any((s) => s['owner_id'] == userId);

        if (alreadyExists) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Une boutique existe déjà pour ce numéro'),
              ),
            );
            return;
          }
        }
      } catch (e) {
        debugPrint('Error checking for existing shop: $e');
      }

      final address = _selectedCity != null && _selectedCommune != null
          ? '$_selectedCity, $_selectedCommune'
          : '';

      final companion = ShopsCompanion.insert(
        name: _nameController.text.trim(),
        description: drift.Value(_descriptionController.text.trim()),
        address: drift.Value(address),
        logoUrl: encryptedLogo.isNotEmpty
            ? drift.Value(encryptedLogo)
            : const drift.Value(''),
        type: _selectedType,
        ownerId: drift.Value(userId),
        phone: drift.Value(_phoneController.text.trim()),
        whatsapp: drift.Value(_whatsappController.text.trim()),
        facebookUrl: drift.Value(_facebookController.text.trim()),
        instagramUrl: drift.Value(_instagramController.text.trim()),
        tiktokUrl: drift.Value(_tiktokController.text.trim()),
        youtubeUrl: drift.Value(_youtubeController.text.trim()),
      );

      final shopId = await shopRepo.addShop(companion);

      // Queue for remote sync
      if (!mounted) return;
      final syncService = context.read<SyncService>();
      await syncService.addToQueue('CREATE', 'shops', {
        'id': shopId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': address,
        'logo_url': finalLogoUrl,
        'type': _selectedType.name,
        'owner_id': userId,
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'facebook_url': _facebookController.text.trim(),
        'instagram_url': _instagramController.text.trim(),
        'tiktok_url': _tiktokController.text.trim(),
        'youtube_url': _youtubeController.text.trim(),
      });

      // Trigger immediate push so the shop appears on the server
      syncService.forcePush();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boutique créée avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      // noop
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: UzaColors.primary),
            const SizedBox(height: 24),
            const Text(
              "Enregistrement...",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Téléchargement et sauvegarde de vos données",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    if (!authService.isPhoneVerified) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Créer une boutique'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: UzaColors.textPrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 80, color: Colors.orange[400]),
                const SizedBox(height: 24),
                const Text(
                  'Vérification requise',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Pour créer et gérer une boutique, vous devez d'abord vérifier votre numéro de téléphone. Cela permet de garantir la sécurité de notre plateforme.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authService.isLoading ? null : () {
                      final phone = authService.user?.phoneNumber ?? '';
                      authService.verifyPhone(
                        phoneNumber: phone,
                        onCodeSent: (verificationId) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerificationScreen(
                                verificationId: verificationId,
                                phoneNumber: phone,
                              ),
                            ),
                          );
                        },
                        onFailed: (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UzaColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: authService.isLoading 
                        ? const SizedBox(
                            width: 24, height: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text('Vérifier mon numéro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_stepLabels[_currentStep]),
        backgroundColor: Colors.white,
        foregroundColor: UzaColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: 4,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentStep + 1) / 6,
              child: Container(color: UzaColors.primary),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Step counter
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  'Étape ${_currentStep + 1} sur 6',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Animated step content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  reverseDuration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    final offsetAnimation =
                        Tween<Offset>(
                          begin: _isGoingForward
                              ? const Offset(0.08, 0)
                              : const Offset(-0.08, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                    return SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentStep),
                    child: _buildStepContent(),
                  ),
                ),
              ),
              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TapAnimator(
                      onTap: _nextStep,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: UzaColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _currentStep == 5 ? 'Publier ma boutique' : 'Suivant',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _previousStep,
                          child: const Text(
                            'Retour',
                            style: TextStyle(
                              color: UzaColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepBoutique();
      case 1:
        return _buildStepContact();
      case 2:
        return _buildStepAbout();
      case 3:
        return _buildStepLocalisation();
      case 4:
        return _buildStepLogo();
      case 5:
        return _buildStepPreview();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepBoutique() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comment s\'appelle ta boutique ?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: UzaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisis un nom simple et facile à retenir.',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom de la boutique *',
              hintText: 'Ex: Boutique Sarah',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: UzaColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            style: const TextStyle(fontSize: 18),
            validator: (v) {
              if (v == null || v.trim().length < 3) {
                return 'Le nom doit faire au moins 3 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<ShopType>(
            initialValue: _selectedType,
            decoration: InputDecoration(
              labelText: 'Type de commerce',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: UzaColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            style: const TextStyle(fontSize: 16, color: UzaColors.textPrimary),
            items: const [
              DropdownMenuItem(value: ShopType.retail, child: Text('Détail')),
              DropdownMenuItem(value: ShopType.wholesale, child: Text('Gros')),
            ],
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContact() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comment tes clients peuvent-ils te joindre ?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: UzaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ton numéro est pré-rempli depuis ton compte.',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Téléphone *',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: UzaColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            style: const TextStyle(fontSize: 18),
            validator: (v) {
              if (v == null || v.trim().isEmpty || v.trim().length < 9) {
                return 'Numéro de téléphone invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _whatsappController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'WhatsApp',
              hintText: 'Optionnel',
              prefixIcon: const Icon(FontAwesomeIcons.whatsapp, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: UzaColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStepAbout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parle-nous de ta boutique',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: UzaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoute une description et tes réseaux sociaux. (Optionnel)',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Décrivez votre boutique...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: UzaColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          _buildSocialField(
            _facebookController,
            'Facebook',
            FontAwesomeIcons.facebook,
          ),
          const SizedBox(height: 16),
          _buildSocialField(
            _instagramController,
            'Instagram',
            FontAwesomeIcons.instagram,
          ),
          const SizedBox(height: 16),
          _buildSocialField(
            _tiktokController,
            'TikTok',
            FontAwesomeIcons.tiktok,
          ),
          const SizedBox(height: 16),
          _buildSocialField(
            _youtubeController,
            'YouTube',
            FontAwesomeIcons.youtube,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: UzaColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildStepLocalisation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Où se trouve ta boutique ?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: UzaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionne ta ville et ta commune.',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            decoration: InputDecoration(
              labelText: 'Ville *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: UzaColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            style: const TextStyle(fontSize: 16, color: UzaColors.textPrimary),
            items: cities.keys.map((city) {
              return DropdownMenuItem(value: city, child: Text(city));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
                _selectedCommune = null;
              });
            },
            validator: (v) => v == null ? 'Sélectionne une ville' : null,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedCity ?? 'none'),
            initialValue: _selectedCommune,
            decoration: InputDecoration(
              labelText: 'Commune *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: UzaColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            style: const TextStyle(fontSize: 16, color: UzaColors.textPrimary),
            items: _selectedCity != null
                ? cities[_selectedCity]!.map((commune) {
                    return DropdownMenuItem(
                      value: commune,
                      child: Text(commune),
                    );
                  }).toList()
                : [],
            onChanged: (value) {
              setState(() => _selectedCommune = value);
            },
            validator: (v) => v == null ? 'Sélectionne une commune' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLogo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Ajoute une photo pour ta boutique',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: UzaColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Cela aide les clients à te reconnaître. (Optionnel)',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          TapAnimator(
            onTap: _showImageSourceSheet,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: UzaColors.primary.withValues(alpha: 0.3),
                  width: 3,
                ),
                image: _logoPreviewBytes != null
                    ? DecorationImage(
                        image: MemoryImage(_logoPreviewBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _logoPreviewBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 48,
                          color: UzaColors.primary.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajouter un logo',
                          style: TextStyle(
                            color: UzaColors.primary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          if (_logoPreviewBytes != null) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => setState(() => _logoPreviewBytes = null),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              label: const Text(
                'Supprimer la photo',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepPreview() {
    final typeLabel = _selectedType == ShopType.retail ? 'Détail' : 'Gros';
    final address = _selectedCity != null && _selectedCommune != null
        ? '$_selectedCity, $_selectedCommune'
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voici comment ta boutique apparaîtra',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: UzaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifie les informations avant de publier.',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 32),
          ModernCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    image: _logoPreviewBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_logoPreviewBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _logoPreviewBytes == null
                      ? Icon(
                          Icons.storefront,
                          size: 32,
                          color: UzaColors.primary.withValues(alpha: 0.5),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : 'Nom de la boutique',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: UzaColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: UzaColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: UzaColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address.isNotEmpty
                                  ? address
                                  : 'Adresse non renseignée',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _phoneController.text.trim().isNotEmpty
                                ? _phoneController.text.trim()
                                : 'Téléphone non renseigné',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (_descriptionController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _descriptionController.text.trim(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (_facebookController.text.trim().isNotEmpty ||
                          _instagramController.text.trim().isNotEmpty ||
                          _tiktokController.text.trim().isNotEmpty ||
                          _youtubeController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (_facebookController.text.trim().isNotEmpty)
                              Icon(
                                FontAwesomeIcons.facebook,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                            if (_instagramController.text.trim().isNotEmpty)
                              Icon(
                                FontAwesomeIcons.instagram,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                            if (_tiktokController.text.trim().isNotEmpty)
                              Icon(
                                FontAwesomeIcons.tiktok,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                            if (_youtubeController.text.trim().isNotEmpty)
                              Icon(
                                FontAwesomeIcons.youtube,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
