import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

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
import '../../core/services/location_service.dart';
import 'shop_profile_screen.dart';

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

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        final isCurrent = index == currentStep - 1;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCurrent ? UzaColors.primary : Colors.grey[300],
          ),
        );
      }),
    );
  }
}

class CreateShopScreen extends StatefulWidget {
  final bool showVerificationOnly;
  const CreateShopScreen({super.key, this.showVerificationOnly = false});

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  ShopType _selectedType = ShopType.retail;
  String? _selectedCity;
  String? _selectedCommune;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Uint8List? _logoPreviewBytes;
  String? _logoUrl;

  int _currentStep = 0;
  bool _isGoingForward = true;

  // Location data
  double? _latitude;
  double? _longitude;
  bool _locationCaptured = false;

  // OTP state
  String? _otpPhoneNumber;
  bool _otpVerified = false;
  bool _otpSkipped = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  int _countdown = 30;
  Timer? _countdownTimer;
  bool _canResend = false;
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  String? _otpErrorMessage;

  final List<String> _stepLabels = [
    'Informations',
    'Contact',
    'Vérification',
    'Détails',
    'Mot de passe',
    'Localisation',
  ];

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ─── Image Picker ────────────────────────────────────────────────

  Future<void> _pickLogo(ImageSource source) async {
    Navigator.pop(context);
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

  // ─── Validation ──────────────────────────────────────────────────

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().length < 3) return false;
        if (_selectedCity == null || _selectedCommune == null) return false;
        return true;
      case 1:
        final phone = _phoneController.text.trim();
        if (phone.isEmpty || phone.length < 9) return false;
        return true;
      case 2:
        return _otpVerified || _otpSkipped;
      case 3:
        return true;
      case 4:
        // Password is mandatory on final step
        if (_passwordController.text.isEmpty ||
            _passwordController.text.length < 6) {
          return false;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          return false;
        }
        return true;
      case 5:
        // Location is optional, always valid
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
      // Auto-trigger OTP send when entering step 2 (index 2)
      if (_currentStep == 2 &&
          !_otpVerified &&
          !_otpSkipped &&
          !_isSendingOtp) {
        _sendOtp();
      }
    } else {
      // Step 5 is location, user will manually submit from there
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
    String message;
    switch (_currentStep) {
      case 0:
        message =
            'Veuillez remplir le nom (min. 3 caractères), la ville et la commune';
        break;
      case 1:
        message = 'Veuillez entrer un numéro de téléphone valide';
        break;
      case 2:
        message = 'Veuillez vérifier votre numéro ou appuyer sur Passer';
        break;
      case 3:
        message = 'Veuillez remplir tous les champs';
        break;
      case 4:
        message = 'Veuillez créer un mot de passe (min. 6 caractères)';
        break;
      case 5:
        message = 'Veuillez capturer la localisation ou passer';
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

  // ─── OTP Logic ───────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isSendingOtp = true;
      _otpPhoneNumber = phone;
    });

    final authService = context.read<AuthService>();
    authService.verifyPhone(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _isSendingOtp = false;
          });
          _startCountdown();
        }
      },
      onFailed: (e) {
        if (mounted) {
          setState(() {
            _isSendingOtp = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: ${e.message}')));
        }
      },
    );
  }

  void _startCountdown() {
    setState(() {
      _countdown = 30;
      _canResend = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  bool get _isOtpComplete {
    return _otpCode.length == 6 &&
        _otpCode.runes.every((r) => r >= 48 && r <= 57);
  }

  void _onOtpChanged(int index, String value) {
    setState(() {
      _otpErrorMessage = null;
    });
    if (value.length == 1) {
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
      if (_isOtpComplete) {
        _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _onOtpKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_otpControllers[index].text.isEmpty && index > 0) {
          _otpControllers[index - 1].clear();
          _otpFocusNodes[index - 1].requestFocus();
        }
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete || _isVerifyingOtp) return;

    setState(() {
      _isVerifyingOtp = true;
      _otpErrorMessage = null;
    });

    final authService = context.read<AuthService>();
    try {
      await authService.signInWithOTP(_otpPhoneNumber!, _otpCode);
      if (mounted) {
        setState(() {
          _otpVerified = true;
          _isVerifyingOtp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Numéro vérifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _otpErrorMessage = e.toString().replaceAll('Exception: ', '');
          _isVerifyingOtp = false;
        });
        for (final c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();
      }
    }
  }

  void _skipOtp() {
    setState(() {
      _otpSkipped = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vous pourrez vérifier votre numéro plus tard dans les paramètres.',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  // ─── Submit ──────────────────────────────────────────────────────

  Future<void> _submitShop() async {
    _showLoadingDialog();

    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      final shopRepo = context.read<ShopRepository>();
      final syncService = context.read<SyncService>();
      final phone = _phoneController.text.trim();

      // 1. Check for existing shop LOCALLY first (prevent duplicate)
      final allShops = await shopRepo.watchAllShops().first;
      final existingLocalShop = allShops
          .where((shop) => shop.phone == phone || shop.ownerId == phone)
          .firstOrNull;

      if (existingLocalShop != null) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Une boutique existe déjà avec ce numéro: ${existingLocalShop.name}',
              ),
              backgroundColor: Colors.orange[800],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),
          );
        }
        return; // Stop the submission process
      }

      // 2. Create / login user
      await authService.registerFromShopFlow(
        phone,
        isPhoneVerified: _otpVerified,
        name: _nameController.text.trim(),
        password: _passwordController.text.trim().isNotEmpty
            ? _passwordController.text.trim()
            : null,
      );

      final userId = authService.user?.uid;
      if (userId == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Erreur de connexion')));
        }
        return;
      }

      // 3. Upload logo if any
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
        }
      }

      final encryptedLogo = finalLogoUrl.isNotEmpty
          ? CryptoUtils.encrypt(finalLogoUrl)
          : '';

      // 4. Check for existing shop on server
      try {
        final shops = await apiService.fetchShops();
        final alreadyExists = shops.any((s) => s['owner_id'] == userId);
        if (alreadyExists && mounted) {
          final navigator = Navigator.of(context);
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Une boutique existe déjà pour ce numéro sur le serveur',
              ),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error checking for existing shop: $e');
      }

      final address = _selectedCity != null && _selectedCommune != null
          ? '$_selectedCity, $_selectedCommune'
          : '';

      // 5. Create local shop
      final companion = ShopsCompanion.insert(
        name: _nameController.text.trim(),
        description: drift.Value(_descriptionController.text.trim()),
        address: drift.Value(address),
        logoUrl: encryptedLogo.isNotEmpty
            ? drift.Value(encryptedLogo)
            : const drift.Value(''),
        type: _selectedType,
        ownerId: drift.Value(userId),
        phone: drift.Value(phone),
        whatsapp: drift.Value(_whatsappController.text.trim()),
        facebookUrl: drift.Value(_facebookController.text.trim()),
        instagramUrl: drift.Value(_instagramController.text.trim()),
        tiktokUrl: drift.Value(_tiktokController.text.trim()),
        youtubeUrl: drift.Value(_youtubeController.text.trim()),
        isVerified: drift.Value(_otpVerified),
        verifiedAt: _otpVerified
            ? drift.Value(DateTime.now())
            : const drift.Value.absent(),
        city: drift.Value(_selectedCity),
        commune: drift.Value(_selectedCommune),
        latitude: drift.Value(_latitude),
        longitude: drift.Value(_longitude),
      );

      final shopId = await shopRepo.addShop(companion);

      // 6. Queue user for remote sync
      await syncService.addToQueue('CREATE', 'users', {
        'remote_id': userId,
        'phone': phone,
        'name': _nameController.text.trim(),
        'is_phone_verified': _otpVerified ? 1 : 0,
      });

      // 7. Queue shop for remote sync
      await syncService.addToQueue('CREATE', 'shops', {
        'local_id': shopId, // kept for local remoteId mapping after push
        'id': shopId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': address,
        'logo_url': finalLogoUrl,
        'type': _selectedType.name,
        'owner_id': userId,
        'phone': phone,
        'whatsapp': _whatsappController.text.trim(),
        'facebook_url': _facebookController.text.trim(),
        'instagram_url': _instagramController.text.trim(),
        'tiktok_url': _tiktokController.text.trim(),
        'youtube_url': _youtubeController.text.trim(),
        'is_verified': _otpVerified ? 1 : 0,
        'verified_at': _otpVerified ? DateTime.now().toIso8601String() : null,
        'city': _selectedCity,
        'commune': _selectedCommune,
        'latitude': _latitude,
        'longitude': _longitude,
      });

      debugPrint('SHOP SYNC QUEUED: Shop ID=$shopId, Owner ID=$userId');
      debugPrint(
        'SHOP SYNC DATA: ${jsonEncode({'id': shopId, 'name': _nameController.text.trim(), 'type': _selectedType.name, 'owner_id': userId, 'phone': phone})}',
      );

      // 8. Trigger immediate push
      await syncService.forcePush();

      // 9. Get the created shop and navigate to profile
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      final createdShop = await shopRepo.getShopById(shopId);
      if (createdShop == null) {
        throw Exception('Boutique créée, mais impossible de la charger.');
      }

      if (mounted) {
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Boutique créée avec succès')),
        );
        // Navigate to shop profile
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => ShopProfileScreen(shop: createdShop),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        navigator.pop(); // Close loading dialog
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _captureLocation() async {
    LocationService.showSecurityNotice(context);
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    LocationService.showLocationLoading(context);

    final location = await LocationService.getCurrentLocation();
    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (location != null) {
      setState(() {
        _latitude = location['latitude']!;
        _longitude = location['longitude']!;
        _locationCaptured = true;
      });

      LocationService.showLocationSuccess(
        context,
        latitude: _latitude!,
        longitude: _longitude!,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de capturer la localisation. Réessayez.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
              "Création de votre compte et boutique",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
              widthFactor: (_currentStep + 1) / 5,
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
        return _buildStepInformations();
      case 1:
        return _buildStepContact();
      case 2:
        return _buildStepVerification();
      case 3:
        return _buildStepDetails();
      case 4:
        return _buildStepPassword();
      case 5:
        return _buildStepLocation();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: Informations ────────────────────────────────────────

  Widget _buildStepInformations() {
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
              labelText: 'Type de commerce *',
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
          const SizedBox(height: 24),
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

  // ─── Step 2: Contact ─────────────────────────────────────────────

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
            'Ton numéro de téléphone servira aussi à te connecter.',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 32),
          IntlPhoneField(
            decoration: InputDecoration(
              labelText: 'Numéro de téléphone *',
              labelStyle: const TextStyle(fontSize: 16),
              hintText: 'XX XXX XX XX',
              hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: UzaColors.divider),
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
                vertical: 22,
              ),
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            initialCountryCode: 'CD',
            disableLengthCheck: false,
            invalidNumberMessage: 'Numéro invalide',
            controller: _phoneController,
            onChanged: (phone) {},
            validator: (phone) {
              if (phone == null || phone.number.length < 9) {
                return 'Entrez un numéro valide';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          IntlPhoneField(
            decoration: InputDecoration(
              labelText: 'Numéro WhatsApp',
              hintText: 'XX XXX XX XX',
              labelStyle: const TextStyle(fontSize: 16),
              hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: UzaColors.divider),
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
                vertical: 22,
              ),
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            initialCountryCode: 'CD',
            disableLengthCheck: false,
            invalidNumberMessage: 'Numéro invalide',
            controller: _whatsappController,
            onChanged: (phone) {},
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Verification ────────────────────────────────────────

  Widget _buildStepVerification() {
    if (_otpVerified) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Numéro vérifié',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre boutique aura le badge "Vérifié"',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_otpSkipped) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Vérification ignorée',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous pourrez vérifier votre numéro plus tard.',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _otpSkipped = false;
                });
                _sendOtp();
              },
              child: const Text(
                'Vérifier maintenant',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vérifie ton téléphone',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: UzaColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Code envoyé au ${_phoneController.text}',
            style: TextStyle(
              color: UzaColors.textSecondary,
              fontSize: 15,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          if (_isSendingOtp)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    width: 48,
                    height: 56,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onOtpKeyEvent(index, event),
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _otpErrorMessage != null
                              ? Colors.red.withValues(alpha: 0.05)
                              : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _otpErrorMessage != null
                                  ? Colors.redAccent
                                  : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _otpErrorMessage != null
                                  ? Colors.redAccent
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: UzaColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onOtpChanged(index, value),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (_otpErrorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _otpErrorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            if (_isVerifyingOtp)
              const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _canResend ? _sendOtp : null,
                child: Text(
                  _canResend
                      ? "Renvoyer le code"
                      : "Renvoyer le code dans ${_countdown}s",
                  style: TextStyle(
                    color: _canResend ? UzaColors.primary : Colors.grey,
                    fontWeight: _canResend
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _isVerifyingOtp ? null : _skipOtp,
                child: const Text(
                  "Passer (non vérifié)",
                  style: TextStyle(
                    color: UzaColors.secondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step 4: Détails ─────────────────────────────────────────────

  Widget _buildStepDetails() {
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
            'Ajoute une description, un logo et tes réseaux sociaux.',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 32),
          // Logo
          Center(
            child: TapAnimator(
              onTap: _showImageSourceSheet,
              child: Container(
                width: 140,
                height: 140,
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
                            size: 40,
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
          ),
          if (_logoPreviewBytes != null) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _logoPreviewBytes = null),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: const Text(
                  'Supprimer la photo',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ],
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
          const SizedBox(height: 16),
          if (!_otpVerified)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Votre boutique sera marquée "Non vérifiée". Vous pourrez vérifier votre numéro plus tard dans les paramètres.',
                      style: TextStyle(color: Colors.orange[800], fontSize: 13),
                    ),
                  ),
                ],
              ),
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

  // ─── Step 5: Password ────────────────────────────────────────────

  Widget _buildStepPassword() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créez votre mot de passe',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: UzaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ce mot de passe vous permettra de vous connecter sur d\'autres appareils',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 32),
          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe *',
              hintText: 'Minimum 6 caractères',
              prefixIcon: const Icon(Icons.lock, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
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
          const SizedBox(height: 24),
          // Confirm password field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe *',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
              ),
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
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: UzaColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: UzaColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: UzaColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Le mot de passe est obligatoire pour sécuriser votre boutique',
                    style: TextStyle(
                      color: UzaColors.primary.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 6: Location ────────────────────────────────────────────

  Widget _buildStepLocation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Localisez votre boutique',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: UzaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aidez vos clients à vous trouver facilement avec GPS',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: UzaColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _locationCaptured ? Icons.check_circle : Icons.location_on,
                size: 60,
                color: _locationCaptured ? Colors.green : UzaColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (_locationCaptured && _latitude != null && _longitude != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Localisation capturée avec succès',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Appuyez sur le bouton ci-dessous pour capturer votre position actuelle',
                      style: TextStyle(color: Colors.orange[800], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _captureLocation,
            icon: Icon(
              _locationCaptured ? Icons.refresh : Icons.my_location,
              size: 20,
            ),
            label: Text(
              _locationCaptured
                  ? 'Recapturer la localisation'
                  : 'Capturer ma position',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: UzaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Skip location and submit
              _submitShop();
            },
            child: Text(
              'Passer cette étape (peut être fait plus tard)',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 5: Preview ─────────────────────────────────────────────

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
          const SizedBox(height: 24),
          ModernCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
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
                          ),
                          if (_otpVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 18,
                            ),
                          ],
                        ],
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
          const SizedBox(height: 16),
          if (!_otpVerified)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Votre boutique sera marquée "Non vérifiée". Vous pourrez vérifier votre numéro plus tard dans les paramètres.',
                      style: TextStyle(color: Colors.orange[800], fontSize: 13),
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
