import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/referral_service.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/res/uza_colors.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/local/uza_database.dart';
import '../../data/services/sync_service.dart';
import 'create_shop_screen.dart';
import 'manage_products_screen.dart';
import 'shop_verification_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'b2b_hub_screen.dart';
import 'orders_screen.dart';
import 'messages_screen.dart';
import 'auth/login_screen.dart';
import '../components/responsive_layout.dart';
import '../components/uza_back_button.dart';
import '../components/arrivage_thumbnail.dart';
import '../components/modern_card.dart';
import '../components/tap_animator.dart';
import '../components/empty_state.dart';
import '../components/async_content.dart';
import '../components/seller_quick_actions.dart';
import '../components/marketing_share_sheet.dart';
import '../components/shop_qr_dialog.dart';
import '../components/shop_share_sheet.dart';
import '../utils/page_transitions.dart';
import '../../core/services/settings_service.dart';
import '../../data/repositories/recently_viewed_repository.dart';
import 'edit_product_screen.dart';
import 'product_detail_screen.dart';
import 'whatsapp_status_screen.dart';
import 'edit_shop_screen.dart';
import 'story_view_screen.dart';
import 'shop_profile_screen.dart';
import 'shop_stats_screen.dart';
import '../../data/repositories/story_repository.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/picker_utils.dart';
import '../../core/utils/image_prepare_utils.dart';
import '../../core/utils/profile_shop_sync.dart';
import 'dart:async';
import 'dart:typed_data';
import '../../core/services/api_service.dart';
import '../../core/l10n/tr.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class ProfileScreen extends StatefulWidget {
  final bool showAppBar;
  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isChangingPassword = false;
  bool _hasReconnectedShops = false;
  String? _lastAuthUid;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  Uint8List? _avatarBytes;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  final Set<String> _failedAvatarUrls = {};
  Uint8List? _coverBytes;
  String? _coverUrl;
  bool _isUploadingCover = false;
  late RecentlyViewedRepository _recentlyViewed;
  late AuthService _authService;
  StreamSubscription<UserProfile?>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _recentlyViewed = RecentlyViewedRepository();
    _recentlyViewed.load();
    _authService = context.read<AuthService>();
    _authService.addListener(_onAuthChanged);
    _profileSubscription = context
        .read<AuthRepository>()
        .watchCurrentUser()
        .listen((profile) {
          if (!mounted || _authService.user == null) return;
          if (profile != null && !_isUploadingAvatar) {
            setState(() => _avatarUrl = profile.avatarUrl);
          }
        });
    _loadUserData();
  }

  void _onAuthChanged() {
    final user = _authService.user;
    if (!mounted) return;
    final uid = user?.uid;
    if (uid != _lastAuthUid) {
      _lastAuthUid = uid;
      _hasReconnectedShops = false;
    }
    if (user != null) {
      setState(() {
        _nameController.text = user.displayName ?? '';
        _phoneController.text = user.phoneNumber ?? '';
      });
    } else {
      _clearLoggedOutUi();
    }
  }

  void _clearLoggedOutUi() {
    setState(() {
      _nameController.clear();
      _phoneController.clear();
      _isEditing = false;
      _avatarUrl = null;
      _avatarBytes = null;
      _coverBytes = null;
      _coverUrl = null;
      _failedAvatarUrls.clear();
    });
  }

  Future<void> _loadUserData() async {
    // Prefer AuthService (reactive source of truth)
    final authService = _authService;
    if (authService.user != null) {
      _nameController.text = authService.user!.displayName ?? '';
      _phoneController.text = authService.user!.phoneNumber ?? '';
    }

    // Load avatar from DB only when a session is active.
    final profile = await context.read<AuthRepository>().getCurrentUser();
    if (profile != null && mounted && authService.user != null) {
      setState(() {
        _nameController.text = authService.user!.displayName ?? profile.name ?? '';
        _phoneController.text = authService.user!.phoneNumber ?? profile.phone;
        _avatarUrl = profile.avatarUrl;
      });
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _authService.removeListener(_onAuthChanged);
    _recentlyViewed.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Safely shows a SnackBar only if the widget is still mounted.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveProfile({Shop? shop}) async {
    setState(() => _isSaving = true);
    if (!mounted) return;

    final name = _nameController.text.trim();
    await context.read<AuthRepository>().updateProfile(
      name: name,
      phone: _phoneController.text,
    );
    context.read<AuthService>().updateDisplayName(name);

    if (shop != null) {
      await ProfileShopSync.syncToShop(context, shop: shop, name: name);
    }

    if (mounted) {
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      _showSnackBar(tr(context, 'profile_updated'));
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty) {
      _showSnackBar('Entrez votre mot de passe actuel', isError: true);
      return;
    }

    if (_newPasswordController.text.isEmpty ||
        _newPasswordController.text.length < 6) {
      _showSnackBar(
        'Le nouveau mot de passe doit contenir au moins 6 caract\u00e8res',
        isError: true,
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Les mots de passe ne correspondent pas', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authService = context.read<AuthService>();
      final authRepo = context.read<AuthRepository>();
      final currentProfile = await authRepo.getCurrentUser();

      if (currentProfile == null) {
        throw Exception('Profil non trouvé');
      }

      // Verify current password
      final currentPasswordHash = _hashPassword(
        _currentPasswordController.text,
      );
      if (currentProfile.passwordHash != currentPasswordHash) {
        throw Exception('Mot de passe actuel incorrect');
      }

      // Update with new password
      final newPasswordHash = _hashPassword(_newPasswordController.text);
      await authRepo.updateProfile(passwordHash: newPasswordHash);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isChangingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        _showSnackBar('Mot de passe modifi\u00e9 avec succ\u00e8s');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'edit_password_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: !_showCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  hintText: 'Minimum 6 caractères',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
            },
            child: Text(tr(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _changePassword,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(tr(context, 'edit_action')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(authService),
        desktop: _buildDesktopLayout(authService),
      ),
    );
  }

  // ─── Desktop Layout ──────────────────────────────────────────────

  Widget _buildDesktopLayout(AuthService authService) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _buildProfileWithShop(authService, isMobile: false),
        ),
      ),
    );
  }

  // ─── Mobile Layout ───────────────────────────────────────────────

  Widget _buildMobileLayout(AuthService authService) {
    return _buildProfileWithShop(authService, isMobile: true);
  }

  Widget _buildProfileWithShop(AuthService authService, {required bool isMobile}) {
    final user = authService.user;
    if (user == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGradientHeader(authService),
            if (isMobile)
              Transform.translate(
                offset: const Offset(0, -24),
                child: _buildContentForUser(authService),
              )
            else ...[
              const SizedBox(height: 24),
              _buildContentForUser(authService),
              const SizedBox(height: 24),
            ],
          ],
        ),
      );
    }

    return StreamBuilder<Shop?>(
      stream: context.read<ShopRepository>().watchUserShop(user.uid),
      builder: (context, snapshot) {
        final shop = snapshot.data;
        if (!isMobile && user != null) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 360,
                  child: _buildGradientHeader(authService, shop: shop),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, right: 24),
                    child: _buildContentForUser(authService),
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGradientHeader(authService, shop: shop),
              if (isMobile)
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: _buildContentForUser(authService),
                )
              else ...[
                const SizedBox(height: 24),
                _buildContentForUser(authService),
                const SizedBox(height: 24),
              ],
              if (isMobile) const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Sources avatar : logo boutique, profil, puis couverture si le logo est cassé.
  List<String?> _avatarSourceCandidates(Shop? shop, MockUser? user) {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return [_avatarUrl, shop?.logoUrl, user?.photoURL, shop?.bannerUrl];
    }
    if (shop != null) {
      return [shop.logoUrl, _avatarUrl, user?.photoURL, shop.bannerUrl];
    }
    return [_avatarUrl, user?.photoURL];
  }

  String? _pickAvatarSource(Shop? shop, MockUser? user) {
    for (final candidate in _avatarSourceCandidates(shop, user)) {
      if (candidate == null || candidate.isEmpty) continue;
      final resolved = ImageUtils.resolveImageUrl(candidate);
      if (resolved != null && !_failedAvatarUrls.contains(resolved)) {
        return candidate;
      }
    }
    return null;
  }

  Widget _buildAvatarIconFallback({required bool hasShopProfile}) {
    return CircleAvatar(
      radius: 48,
      backgroundColor: Colors.white.withValues(alpha: 0.25),
      child: Icon(
        hasShopProfile ? Icons.store : Icons.person,
        size: 48,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _buildProfileAvatar({
    required Shop? shop,
    required MockUser? user,
    required bool hasShopProfile,
  }) {
    if (_isUploadingAvatar) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      );
    }

    if (_avatarBytes != null) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        backgroundImage: MemoryImage(_avatarBytes!),
      );
    }

    final avatarSource = _pickAvatarSource(shop, user);
    if (avatarSource == null) {
      return _buildAvatarIconFallback(hasShopProfile: hasShopProfile);
    }

    final resolved = ImageUtils.resolveImageUrl(avatarSource)!;
    return ClipOval(
      child: SizedBox(
        width: 96,
        height: 96,
        child: KeyedSubtree(
          key: ValueKey(resolved),
          child: ImageUtils.buildCachedImage(
            avatarSource,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          placeholder: CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          errorWidget: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _failedAvatarUrls.add(resolved)) {
                  setState(() {});
                }
              });
              return _buildAvatarIconFallback(hasShopProfile: hasShopProfile);
            },
          ),
        ),
      ),
      ),
    );
  }

  // ─── Gradient Header ─────────────────────────────────────────────

  Widget _buildGradientHeader(AuthService authService, {Shop? shop}) {
    final user = authService.user;
    final hasShopProfile = user != null && shop != null;
    final displayName = hasShopProfile
        ? shop!.name
        : (user?.displayName ?? '');
    final phoneNumber = user?.phoneNumber ?? '';
    final hasBanner = _coverUrl != null ||
        (hasShopProfile &&
            shop.bannerUrl != null &&
            shop.bannerUrl!.isNotEmpty &&
            ImageUtils.resolveImageUrl(shop.bannerUrl) != null);
    final coverSource = _coverUrl ?? shop?.bannerUrl;
    final canEditCover =
        hasShopProfile && user != null && !_isUploadingCover;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: hasShopProfile ? 160 : 160,
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: canEditCover ? _showCoverSourceSheet : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_coverBytes != null)
                      Image.memory(_coverBytes!, fit: BoxFit.cover)
                    else if (hasBanner && coverSource != null)
                      KeyedSubtree(
                        key: ValueKey(
                          ImageUtils.resolveImageUrl(coverSource) ?? coverSource,
                        ),
                        child: ImageUtils.buildCachedImage(
                          coverSource,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    else
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [UzaColors.primary, Color(0xFFD84315)],
                          ),
                        ),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(
                              alpha: hasBanner ? 0.45 : 0.1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isUploadingCover)
                      Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
          // Top row: back + edit/save
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              widget.showAppBar
                  ? const UzaBackButton(onDarkBackground: true)
                  : const SizedBox(width: 48),
              if (_isEditing && user != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasShopProfile)
                      IconButton(
                        icon: const Icon(
                          Icons.photo_camera_outlined,
                          color: Colors.white,
                        ),
                        tooltip: 'Modifier la couverture',
                        onPressed: _isUploadingCover
                            ? null
                            : _showCoverSourceSheet,
                      ),
                    TextButton.icon(
                      onPressed:
                          _isSaving ? null : () => _saveProfile(shop: shop),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check, color: Colors.white, size: 18),
                      label: Text(
                        _isSaving ? tr(context, 'saving') : tr(context, 'save'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              else if (user != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasShopProfile)
                      IconButton(
                        icon: const Icon(
                          Icons.photo_camera_outlined,
                          color: Colors.white,
                        ),
                        tooltip: 'Modifier la couverture',
                        onPressed: _isUploadingCover
                            ? null
                            : _showCoverSourceSheet,
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: () {
                        if (shop != null) {
                          _nameController.text = shop.name;
                        }
                        setState(() => _isEditing = true);
                      },
                    ),
                  ],
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          if (canEditCover) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _showCoverSourceSheet,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_camera_outlined,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Modifier la couverture',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          // Avatar with camera overlay
          GestureDetector(
            onTap: (user != null && !_isUploadingAvatar)
                ? _pickAvatarImage
                : null,
            child: Stack(
              children: [
                _buildProfileAvatar(
                  shop: shop,
                  user: user,
                  hasShopProfile: hasShopProfile,
                ),
                if (_isEditing && user != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: UzaColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Name (editable or display)
          if (_isEditing && user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _nameController,
                enabled: !_isSaving,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: hasShopProfile
                      ? 'Nom de la boutique'
                      : tr(context, 'full_name'),
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            )
          else
            Text(
              displayName.isEmpty
                  ? (user == null
                        ? tr(context, 'not_connected')
                        : tr(context, 'user'))
                  : displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          if (user != null)
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _phoneController,
                  enabled: false,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: tr(context, 'phone_number'),
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    disabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              )
            else
              Text(
                phoneNumber,
                style: TextStyle(
                  color: phoneNumber.isEmpty
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Content Sections ────────────────────────────────────────────

  Widget _buildContentForUser(AuthService authService) {
    final user = authService.user;
    if (user == null) return _buildLoggedOutContent(authService);

    if (!_hasReconnectedShops) {
      _hasReconnectedShops = true;
      context.read<ShopRepository>().reconnectShopsForUser(user.uid);
    }

    return StreamBuilder<Shop?>(
      stream: context.read<ShopRepository>().watchUserShop(user.uid),
      builder: (context, snapshot) {
        final hasShop = snapshot.hasData && snapshot.data != null;
        final shop = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsRow(shop),
            if (shop != null) ...[
              const SizedBox(height: 12),
              _buildShopStatsEntry(shop),
            ],
            const SizedBox(height: 20),
            if (hasShop) ...[
              _buildSectionTitle(tr(context, 'my_shops')),
              _buildShopCard(shop!),
              const SizedBox(height: 12),
              _buildShareShopEntry(shop),
              const SizedBox(height: 12),
              _buildEditShopEntry(shop),
              const SizedBox(height: 12),
              if (!shop.isVerified) ...[
                _buildVerifyShopBanner(shop),
                const SizedBox(height: 12),
              ],
              _buildSectionTitle('Outils vendeur'),
              SellerQuickActions(shop: shop),
              const SizedBox(height: 12),
              _buildManageProductsEntry(shop),
              const SizedBox(height: 12),
              _buildMyProducts(shop),
              _buildMyStories(shop),
              _buildMyArrivages(shop),
            ] else ...[
              _buildShopOnboardingSection(),
              const SizedBox(height: 16),
              _buildFollowedShops(),
              const SizedBox(height: 16),
              _buildRecentlyViewed(),
              const SizedBox(height: 16),
              _buildWishlist(),
              const SizedBox(height: 16),
            ],
            _buildSectionTitle(tr(context, 'settings')),
            _buildSettingsSection(authService, showWaStatusToggle: hasShop),
            const SizedBox(height: 16),
            _buildSectionTitle(tr(context, 'account')),
            _buildAccountSection(authService),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  // ─── Stats Row ───────────────────────────────────────────────────

  Widget _buildStatsRow(Shop? shop) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _statCardWidget(
              icon: Icons.inventory_2_outlined,
              label: tr(context, 'products'),
              valueWidget: shop != null
                  ? StreamBuilder<List<Product>>(
                      stream: context
                          .read<ProductRepository>()
                          .watchProductsByShop(shop.id),
                      builder: (context, snap) => Text(
                        '${snap.data?.length ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : const Text(
                      '0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCardWidget(
              icon: Icons.store_outlined,
              label: tr(context, 'shops'),
              valueWidget: Text(
                shop != null ? '1' : '0',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCardWidget(
              icon: Icons.visibility_outlined,
              label: tr(context, 'views'),
              onTap: shop != null
                  ? () => _openShopStats(shop)
                  : null,
              valueWidget: shop != null
                  ? FutureBuilder<Map<String, int>>(
                      future: context.read<ShopRepository>().getShopStats(
                        shop.id,
                      ),
                      builder: (context, snap) => Text(
                        '${snap.data?['totalViews'] ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : const Text(
                      '—',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          if (shop != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _statCardWidget(
                icon: Icons.collections_outlined,
                iconColor: const Color(0xFF25D366),
                label: 'Statut WA',
                highlighted: true,
                onTap: () => Navigator.push(
                  context,
                  SlideUpRoute(page: WhatsAppStatusScreen(shop: shop)),
                ),
                valueWidget: StreamBuilder<List<Product>>(
                  stream: context
                      .read<ProductRepository>()
                      .watchProductsByShop(shop.id),
                  builder: (context, snap) {
                    final count = (snap.data ?? [])
                        .where(
                          (p) =>
                              !p.isSold &&
                              ImageUtils.hasDisplayableImage(p.imageUrls),
                        )
                        .length;
                    return Icon(
                      Icons.bolt,
                      color: const Color(0xFF25D366),
                      size: count > 0 ? 22 : 18,
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openShopStats(Shop shop) {
    Navigator.push(
      context,
      SlideUpRoute(page: ShopStatsScreen(shopId: shop.id)),
    );
  }

  Widget _buildShopStatsEntry(Shop shop) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ModernCard(
        padding: EdgeInsets.zero,
        onTap: () => _openShopStats(shop),
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics_outlined, color: Colors.deepPurple),
          ),
          title: Text(
            tr(context, 'show_stats'),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: FutureBuilder<Map<String, int>>(
            future: context.read<ShopRepository>().getWeeklyStats(shop.id),
            builder: (context, snap) {
              final weekly = snap.data ?? {};
              final views = weekly['weeklyViews'] ?? 0;
              final contacts = weekly['weeklyContacts'] ?? 0;
              return Text(
                '$views vues · $contacts contacts (7 jours)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              );
            },
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _statCardWidget({
    required IconData icon,
    required String label,
    required Widget valueWidget,
    Color? iconColor,
    VoidCallback? onTap,
    bool highlighted = false,
  }) {
    final theme = Theme.of(context);
    final waGreen = const Color(0xFF25D366);
    final card = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? Color.alphaBlend(
                waGreen.withValues(alpha: 0.14),
                theme.colorScheme.surface,
              )
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: highlighted
            ? Border.all(color: waGreen.withValues(alpha: 0.35))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? UzaColors.primary, size: 18),
          const SizedBox(height: 4),
          valueWidget,
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.1,
              color: highlighted
                  ? waGreen.withValues(alpha: 0.85)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }

  // ─── Section Title ───────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  // ─── Shop Card (Mes Boutiques) ──────────────────────────────────

  Widget _buildShopCard(Shop shop) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      onTap: () => Navigator.push(
        context,
        SlideUpRoute(page: ShopProfileScreen(shop: shop)),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ImageUtils.getLogoWidget(shop.logoUrl, size: 44),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                shop.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (shop.isVerified) ...[
              const SizedBox(width: 4),
              Icon(Icons.verified, size: 16, color: UzaColors.secondary),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildShareShopEntry(Shop shop) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: () => ShopShareSheet.show(context, shop),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.share_outlined, color: Colors.blue),
        ),
        title: const Text(
          'Partager ma boutique',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          'Lien, QR code, WhatsApp…',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.qr_code_2, color: UzaColors.primary),
              tooltip: 'QR Code',
              onPressed: () => ShopQrDialog.show(context, shop),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildEditShopEntry(Shop shop) {
    return ModernCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(
        context,
        SlideUpRoute(page: EditShopScreen(shop: shop)),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: UzaColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.photo_library_outlined,
            color: UzaColors.primary,
          ),
        ),
        title: const Text(
          'Modifier ma boutique',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          'Logo, couverture, description, réseaux sociaux',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  // ─── Verify Shop Banner ─────────────────────────────────────────

  Widget _buildVerifyShopBanner(Shop shop) {
    return ModernCard(
      backgroundColor: Colors.orange.withValues(alpha: 0.08),
      hasBorder: true,
      padding: const EdgeInsets.all(16),
      onTap: () async {
        final result = await Navigator.push(
          context,
          SlideUpRoute(page: ShopVerificationScreen(shop: shop)),
        );
        // Refresh the screen if verification was successful
        if (result == true && mounted) {
          setState(() {});
        }
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vérifier votre boutique',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gagnez la confiance des clients avec un badge vérifié.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildManageProductsEntry(Shop shop) {
    return ModernCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(
        context,
        SlideUpRoute(page: ManageProductsScreen(shopId: shop.id)),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: Colors.orange,
          ),
        ),
        title: const Text(
          'Gérer mes produits',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          'Modifier, supprimer ou marquer comme vendu',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  // ─── My Products (Seller) ───────────────────────────────────────

  Widget _buildMyProducts(Shop shop) {
    return StreamBuilder<List<Product>>(
      stream: context.read<ProductRepository>().watchProductsByShop(shop.id),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(tr(context, 'my_products')),
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      tr(context, 'no_products_yet'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          context.read<SyncService>().syncNow(),
                      icon: const Icon(Icons.refresh),
                      label: Text(tr(context, 'retry')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }
        final display = products.take(4).toList();
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(tr(context, 'my_products')),
            ModernCard(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: display.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final p = display[index];
                final images = ImageUtils.getDecryptedList(p.imageUrls);
                final firstImage = images.isNotEmpty ? images.first : null;
                return TapAnimator(
                  onTap: () => Navigator.push(
                    context,
                    SlideUpRoute(page: ProductDetailScreen(product: p)),
                  ),
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Center(
                                child: firstImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: ImageUtils.buildCachedImage(
                                          firstImage,
                                          fit: BoxFit.cover,
                                          placeholder: Container(
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.inventory_2_outlined,
                                              color: Colors.grey[400],
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.grey[400],
                                        size: 28,
                                      ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    SlideUpRoute(
                                      page: EditProductScreen(
                                        shopId: shop.id,
                                        product: p,
                                      ),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: UzaColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _confirmDeleteProduct(context, p),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${p.viewsCount}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // ─── My Stories (Seller) ──────────────────────────────────────────

  Widget _buildMyStories(Shop shop) {
    return StreamBuilder<List<Story>>(
      stream: context.read<StoryRepository>().watchStoriesByShop(shop.id),
      builder: (context, snapshot) {
        final stories = snapshot.data ?? [];
        if (stories.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(tr(context, 'my_stories')),
            ModernCard(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final story = stories[index];
                return Stack(
                  key: ValueKey('my_story_${story.id}'),
                  children: [
                    TapAnimator(
                      onTap: () async {
                        final storyRepo = context.read<StoryRepository>();
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoryViewScreen(
                              stories: stories,
                              initialIndex: index,
                              shopLookup: {shop.id: shop},
                              getViewCount: storyRepo.getStoryViewCount,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.purple.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: ImageUtils.buildCachedImage(
                                story.mediaUrl,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: Colors.purple[300],
                                    size: 24,
                                  ),
                                ),
                                errorWidget: Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: Colors.purple[300],
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            story.mediaType == 'video' ? 'Vidéo' : 'Photo',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _confirmDeleteStory(context, story),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // ─── My Arrivages (Seller) ──────────────────────────────────────────

  Widget _buildMyArrivages(Shop shop) {
    return StreamBuilder<List<Story>>(
      stream: context.read<StoryRepository>().watchArrivagesByShop(shop.id),
      builder: (context, snapshot) {
        final arrivages = snapshot.data ?? [];
        if (arrivages.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(tr(context, 'my_arrivages')),
            ModernCard(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: arrivages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final arrivage = arrivages[index];
                return Stack(
                  children: [
                    TapAnimator(
                      onTap: () async {
                        final storyRepo = context.read<StoryRepository>();
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoryViewScreen(
                              stories: arrivages,
                              initialIndex: index,
                              shopLookup: {shop.id: shop},
                              getViewCount: storyRepo.getStoryViewCount,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: UzaColors.secondary.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: ArrivageThumbnail(
                                story: arrivage,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.local_shipping,
                                    color: UzaColors.secondary.withValues(
                                      alpha: 0.6,
                                    ),
                                    size: 24,
                                  ),
                                ),
                                errorWidget: Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.local_shipping,
                                    color: UzaColors.secondary.withValues(
                                      alpha: 0.6,
                                    ),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            arrivage.mediaType == 'video' ? 'Vidéo' : 'Photo',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _confirmDeleteStory(context, arrivage),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // ─── Shop onboarding (guest + logged-in without shop) ───────────

  Widget _buildShopOnboardingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Icon(Icons.storefront, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            tr(context, 'sell_on_uzaapp'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                SlideUpRoute(page: const CreateShopScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: UzaColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                tr(context, 'create_shop'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              SlideUpRoute(page: const LoginScreen()),
            ),
            child: Text(tr(context, 'already_have_account')),
          ),
        ],
      ),
    );
  }

  // ─── Followed Shops ─────────────────────────────────────────────

  Widget _buildFollowedShops() {
    return StreamBuilder<List<Shop>>(
      stream: context.read<ShopRepository>().watchFollowedShops(),
      builder: (context, snapshot) {
        final shops = snapshot.data ?? [];
        if (shops.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                tr(context, 'followed_sellers'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shops.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return TapAnimator(
                    onTap: () => Navigator.push(
                      context,
                      SlideUpRoute(page: ShopProfileScreen(shop: shop)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: UzaColors.secondary.withValues(alpha: 0.1),
                            border: shop.isVerified
                                ? Border.all(
                                    color: UzaColors.secondary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            Icons.store,
                            color: UzaColors.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 64,
                          child: Text(
                            shop.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Recently Viewed (Buyer) ────────────────────────────────────

  Widget _buildRecentlyViewed() {
    return AnimatedBuilder(
      animation: _recentlyViewed,
      builder: (context, _) {
        final items = _recentlyViewed.items;
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                tr(context, 'history'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.take(10).length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return TapAnimator(
                    onTap: () {
                      if (item.type == 'product') {
                        context
                            .read<ProductRepository>()
                            .getProductById(int.parse(item.id))
                            .then((product) {
                              if (product != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  SlideUpRoute(
                                    page: ProductDetailScreen(product: product),
                                  ),
                                );
                              }
                            });
                      }
                    },
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (item.price != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.price!,
                              style: TextStyle(
                                fontSize: 11,
                                color: UzaColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Wishlist (Buyer) ───────────────────────────────────────────

  Widget _buildWishlist() {
    return StreamBuilder<List<Product>>(
      stream: context.read<ProductRepository>().watchWishlistProducts(),
      builder: (context, snapshot) {
        if (AsyncContent.isLoading(snapshot)) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: EmptyState(
              icon: Icons.favorite_border,
              title: tr(context, 'wishlist_empty'),
              subtitle: tr(context, 'wishlist_empty_hint'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr(context, 'my_list'),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${products.length} produit${products.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: UzaColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.take(10).length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final p = products[index];
                  return TapAnimator(
                    onTap: () => Navigator.push(
                      context,
                      SlideUpRoute(page: ProductDetailScreen(product: p)),
                    ),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.price ?? ''} CDF',
                            style: TextStyle(
                              fontSize: 11,
                              color: UzaColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Settings Section (Paramètres) ──────────────────────────────

  Widget _buildSettingsSection(
    AuthService authService, {
    bool showWaStatusToggle = false,
  }) {
    final settings = context.watch<SettingsService>();
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // Change password
          TapAnimator(
            onTap: () => _showChangePasswordDialog(),
            child: ListTile(
              leading: Icon(Icons.lock_outline, color: Colors.grey[700]),
              title: Text(
                'Mot de passe',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'Modifier votre mot de passe',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey[400],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          ListTile(
            leading: Icon(Icons.dark_mode_outlined, color: Colors.indigo),
            title: Text(
              tr(context, 'dark_mode'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              trThemeMode(context, settings.themeModePreference),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey[400],
            ),
            onTap: () => Navigator.push(
              context,
              SlideUpRoute(page: const SettingsScreen()),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          // Lite mode
          SwitchListTile(
            secondary: Icon(Icons.bolt_outlined, color: UzaColors.primary),
            title: Text(
              tr(context, 'lite_mode'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              settings.isLiteMode
                  ? tr(context, 'enabled')
                  : tr(context, 'disabled'),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            value: settings.isLiteMode,
            onChanged: (val) => settings.toggleLiteMode(val),
            activeThumbColor: UzaColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          // Language
          TapAnimator(
            onTap: () => Navigator.push(
              context,
              SlideUpRoute(page: const SettingsScreen()),
            ),
            child: ListTile(
              leading: Icon(Icons.language, color: Colors.grey[700]),
              title: Text(
                tr(context, 'language'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    settings.currentLanguage.toUpperCase(),
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          // Notifications
          SwitchListTile(
            secondary: Icon(
              Icons.notifications_outlined,
              color: Colors.amber[700],
            ),
            title: Text(
              tr(context, 'notifications'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            value: settings.notificationsEnabled,
            onChanged: (val) => settings.toggleNotifications(val),
            activeThumbColor: UzaColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          if (showWaStatusToggle) ...[
            const Divider(height: 1, indent: 12, endIndent: 12),
            SwitchListTile(
              secondary: const Icon(
                Icons.collections_outlined,
                color: Color(0xFF25D366),
              ),
              title: Text(
                tr(context, 'wa_status_auto'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                settings.waStatusAutoEnabled
                    ? tr(context, 'wa_status_auto_on')
                    : tr(context, 'wa_status_auto_off'),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              value: settings.waStatusAutoEnabled,
              onChanged: (val) => settings.toggleWaStatusAuto(val),
              activeThumbColor: UzaColors.primary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ],
          // Admin section (conditional)
          if (authService.user?.isAdmin == true) ...[
            const Divider(height: 1, indent: 12, endIndent: 12),
            TapAnimator(
              onTap: () => context.push('/admin'),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                title: Text(
                  tr(context, 'admin_panel'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  tr(context, 'admin_panel_hint'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Account Section (Compte) ───────────────────────────────────

  Widget _buildAccountSection(AuthService authService) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          TapAnimator(
            onTap: () => Navigator.push(
              context,
              SlideUpRoute(page: const OrdersScreen()),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.receipt_long_outlined,
                color: UzaColors.primary,
              ),
              title: Text(
                tr(context, 'my_orders'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          TapAnimator(
            onTap: () => Navigator.push(
              context,
              SlideUpRoute(page: const MessagesScreen()),
            ),
            child: ListTile(
              leading: Icon(
                Icons.chat_bubble_outline,
                color: UzaColors.secondary,
              ),
              title: Text(
                tr(context, 'messages'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          TapAnimator(
            onTap: () => Navigator.push(
              context,
              SlideUpRoute(page: const B2BHubScreen()),
            ),
            child: ListTile(
              leading: Icon(
                Icons.business_center_outlined,
                color: UzaColors.secondary,
              ),
              title: Text(
                tr(context, 'b2b_hub'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          TapAnimator(
            onTap: () =>
                Navigator.push(context, SlideUpRoute(page: const HelpScreen())),
            child: ListTile(
              leading: Icon(
                Icons.help_outline_rounded,
                color: Colors.blue[700],
              ),
              title: Text(
                tr(context, 'help'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          TapAnimator(
            onTap: () async {
              final phone = authService.user?.phoneNumber ?? 'guest';
              final referral = context.read<ReferralService>();
              final code = await referral.getOrCreateCode(phone);
              final shop = await context.read<ShopRepository>().getUserShop(phone);
              if (!context.mounted) return;
              await MarketingShareSheet.showReferralInvite(
                context,
                message: referral.inviteMessage(
                  referralCode: code,
                  shopName: shop?.name,
                ),
              );
            },
            child: ListTile(
              leading: Icon(Icons.group_add_rounded, color: Colors.green[700]),
              title: Text(
                tr(context, 'invite_friends'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          TapAnimator(
            onTap: () async {
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red[700]),
              title: Text(
                tr(context, 'logout'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.red[300],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Delete Confirmation Dialogs ─────────────────────────────────

  void _confirmDeleteProduct(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'delete_confirm_title')),
        content: Text(
          trf(context, 'delete_product_named', {'name': product.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () async {
              final repo = context.read<ProductRepository>();
              final syncService = context.read<SyncService>();
              Navigator.pop(context);
              await repo.deleteProductWithSync(product.id);
              unawaited(syncService.forcePush());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr(context, 'product_deleted_success')),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(tr(context, 'delete'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStory(BuildContext context, Story story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context, 'delete_confirm_title')),
        content: Text(
          story.isArrivage
              ? 'Voulez-vous vraiment supprimer cet arrivage ?'
              : 'Voulez-vous vraiment supprimer cette story ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<StoryRepository>().deleteStoryWithSync(
                story.id,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr(context, 'deleted_success')),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(tr(context, 'delete'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── Avatar Image Picker ───────────────────────────────────────

  Future<void> _showCoverSourceSheet() async {
    await _pickCoverImage();
  }

  Future<void> _pickCoverImage() async {
    try {
      final bytes = await PickerUtils.pickImage(context);
      if (bytes == null || !mounted) return;

      setState(() {
        _coverBytes = bytes;
        _isUploadingCover = true;
      });

      final authService = context.read<AuthService>();
      final userId = authService.user?.uid;
      if (userId == null) {
        _showSnackBar('Connectez-vous pour modifier la couverture', isError: true);
        return;
      }

      final shop = await context.read<ShopRepository>().getUserShop(userId);
      if (shop == null || !mounted) {
        _showSnackBar('Boutique introuvable', isError: true);
        return;
      }

      final previousCover = _coverUrl ?? shop.bannerUrl;

      final prepared = await ImagePrepareUtils.prepareForUpload(
        bytes,
        prefix: 'shop_banner_${shop.id}',
      );
      final uploadedUrl = await context.read<ApiService>().uploadFileOrThrow(
        prepared.bytes,
        prepared.fileName,
        folder: 'boutiques',
      );

      if (!mounted) return;
      await ImageUtils.evictCachedSources([previousCover, uploadedUrl]);
      await ProfileShopSync.syncToShop(
        context,
        shop: shop,
        bannerUrl: uploadedUrl,
      );
      await ImageUtils.prefetchUrls([uploadedUrl]);
      if (mounted) {
        setState(() {
          _coverUrl = uploadedUrl;
          _coverBytes = null;
        });
      }
      _showSnackBar('Couverture mise à jour');
    } catch (e) {
      if (mounted) {
        _showSnackBar('${tr(context, 'upload_error')}: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingCover = false);
      }
    }
  }

  Future<void> _pickAvatarImage() async {
    try {
      final bytes = await PickerUtils.pickImage(context);
      if (bytes == null || !mounted) return;

      setState(() {
        _avatarBytes = bytes;
        _isUploadingAvatar = true;
      });

      final prepared = await ImagePrepareUtils.prepareForUpload(
        bytes,
        prefix: 'avatar',
      );
      final apiService = context.read<ApiService>();
      final authService = context.read<AuthService>();
      final uploadedUrl = await apiService.uploadFileOrThrow(
        prepared.bytes,
        prepared.fileName,
        folder: 'boutiques',
      );

      if (!mounted) return;
      final previousUrl = _avatarUrl ?? authService.user?.photoURL;
      if (previousUrl != null) {
        final resolvedPrevious = ImageUtils.resolveImageUrl(previousUrl);
        if (resolvedPrevious != null) {
          try {
            await UzaImageCache.instance.removeFile(resolvedPrevious);
          } catch (_) {}
        }
      }

      await ProfileShopSync.syncToProfile(
        context,
        avatarUrl: uploadedUrl,
      );

      final userId = authService.user?.uid;
      if (userId != null) {
        final shop = await context.read<ShopRepository>().getUserShop(userId);
        if (shop != null && mounted) {
          await ProfileShopSync.syncToShop(
            context,
            shop: shop,
            logoUrl: uploadedUrl,
          );
        }
      }

      await ImageUtils.prefetchUrls([uploadedUrl]);
      if (mounted) {
        setState(() {
          _avatarUrl = uploadedUrl;
          _avatarBytes = null;
          _failedAvatarUrls.clear();
        });
      }
      _showSnackBar(tr(context, 'profile_updated'));
    } catch (e) {
      if (mounted) {
        _showSnackBar(tr(context, 'upload_error'), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  // ─── Logged Out Content ─────────────────────────────────────────

  Widget _buildLoggedOutContent(AuthService authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildShopOnboardingSection(),
        _buildSectionTitle(tr(context, 'settings')),
        _buildGuestSettingsSection(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildGuestSettingsSection() {
    final settings = context.watch<SettingsService>();
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.dark_mode_outlined, color: Colors.indigo),
            title: Text(
              tr(context, 'dark_mode'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              trThemeMode(context, settings.themeModePreference),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey[400],
            ),
            onTap: () => Navigator.push(
              context,
              SlideUpRoute(page: const SettingsScreen()),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          const Divider(height: 1, indent: 12, endIndent: 12),
          TapAnimator(
            onTap: () => Navigator.push(
              context,
              SlideUpRoute(page: const SettingsScreen()),
            ),
            child: ListTile(
              leading: Icon(Icons.language, color: Colors.grey[700]),
              title: Text(
                tr(context, 'language'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey[400],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }
}
