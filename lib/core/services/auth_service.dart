import 'dart:async';
import 'dart:math';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/local/uza_database.dart';
import '../../data/services/sync_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sms_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../utils/phone_utils.dart';

class MockUser {
  final String uid;
  final String? phoneNumber;
  final String? displayName;
  final String? photoURL;
  final String role;

  MockUser({
    required this.uid,
    this.phoneNumber,
    this.displayName,
    this.photoURL,
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';
}

class AuthService extends ChangeNotifier {
  final AuthRepository _repository;
  SyncService? _syncService;
  ShopRepository? _shopRepository;

  MockUser? _currentUser;
  bool _isLoading = false;
  bool _isPhoneVerified = false;

  // Store the last generated OTP code for verification
  String? _lastOtpCode;
  String? _lastOtpPhone;
  DateTime? _lastOtpSentAt;
  // Production: 10 minutes | Testing: 2 minutes
  static const Duration _otpExpiryDuration = Duration(minutes: 2);

  AuthService(this._repository) {
    // Defer session loading to avoid MissingPluginException on web
    // Plugin registration happens asynchronously on web platform
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSession();
    });
  }

  set syncService(SyncService? service) {
    _syncService = service;
  }

  set shopRepository(ShopRepository? repo) {
    _shopRepository = repo;
  }

  bool get isLoading => _isLoading;
  bool get isPhoneVerified => _isPhoneVerified;
  MockUser? get user => _currentUser;

  bool _isSamePhone(String first, String second) {
    return _phoneVariations(first).any(_phoneVariations(second).contains);
  }

  List<String> _phoneVariations(String phone) {
    final cleaned = phone.trim().replaceAll(RegExp(r'\s+'), '');
    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    final variations = <String>{cleaned, digits};

    if (digits.startsWith('243') && digits.length >= 12) {
      final local = digits.substring(3);
      variations.add(local);
      variations.add('0$local');
      variations.add(digits);
      variations.add('+$digits');
    } else if (digits.startsWith('0') && digits.length >= 10) {
      final withoutLeading0 = digits.substring(1);
      variations.add(withoutLeading0);
      variations.add('243$withoutLeading0');
      variations.add('+243$withoutLeading0');
    } else if (digits.length == 9) {
      variations.add('0$digits');
      variations.add('243$digits');
      variations.add('+243$digits');
    }

    variations.removeWhere((value) => value.isEmpty);
    return variations.toList();
  }

  /// Restores the user session from the local database.
  ///
  /// The user's phone number is the stable identifier (uid) across app
  /// updates and re-logins. If [remoteId] is empty (e.g. after logout
  /// cleared it), we fall back to [phone] so that shops owned by this
  /// phone number are immediately visible via [watchUserShop].
  Future<void> _loadSession() async {
    try {
      // Guard against MissingPluginException on web during early initialization
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        if (kIsWeb || (e.toString().contains('MissingPluginException'))) {
          if (kDebugMode) {
            debugPrint(
              'AuthService: SharedPreferences not available yet (web), skipping',
            );
          }
        } else {
          rethrow;
        }
      }

      final profile = await _repository.getCurrentUser();
      if (profile != null &&
          profile.remoteId != null &&
          profile.remoteId!.isNotEmpty) {
        _isPhoneVerified = profile.isPhoneVerified;
        // remoteId is only set after a real login or shop creation flow.
        // After logout it is cleared — do not auto-restore a session from
        // the preserved phone/name row alone.
        final uid = PhoneUtils.normalizeDrc(profile.remoteId!).isNotEmpty
            ? PhoneUtils.normalizeDrc(profile.remoteId!)
            : profile.remoteId!;
        _currentUser = MockUser(
          uid: uid,
          phoneNumber: PhoneUtils.normalizeDrc(profile.phone).isNotEmpty
              ? PhoneUtils.normalizeDrc(profile.phone)
              : profile.phone,
          displayName: profile.name,
          photoURL: profile.avatarUrl,
          role: profile.role,
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Error loading session: $e');
      }
      // Give up — user will need to log in again
    }
  }

  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(dynamic e) onFailed,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String otpCode;
      if (_lastOtpCode != null && _lastOtpPhone == phoneNumber) {
        otpCode = _lastOtpCode!;
      } else {
        final random = Random();
        otpCode = (100000 + random.nextInt(900000)).toString();
      }

      final smsSent = await SmsService.envoyerCodeOtp(phoneNumber, otpCode);

      if (smsSent) {
        _lastOtpCode = otpCode;
        _lastOtpPhone = phoneNumber;
        _lastOtpSentAt = DateTime.now();
        if (kDebugMode) {
          debugPrint('AuthService: OTP SMS sent to $phoneNumber');
        }
        onCodeSent(phoneNumber);
      } else if (kDebugMode) {
        _lastOtpCode = null;
        _lastOtpPhone = phoneNumber;
        _lastOtpSentAt = DateTime.now();
        debugPrint('AuthService: SMS failed — debug OTP bypass enabled');
        onCodeSent(phoneNumber);
      } else {
        throw Exception(
          'Impossible d\'envoyer le SMS. Vérifiez votre connexion et réessayez.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Error sending OTP: $e');
      }
      onFailed(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithOTP(String verificationId, String smsCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Normalize phone numbers for comparison (remove all non-digit chars except +)
      String normalizePhone(String phone) =>
          phone.replaceAll(RegExp(r'[^\d+]'), '');
      final enteredPhone = normalizePhone(verificationId);
      final storedPhone = _lastOtpPhone != null
          ? normalizePhone(_lastOtpPhone!)
          : '';

      if (kDebugMode) {
        debugPrint(
          'AuthService: Verifying OTP for phone=$enteredPhone',
        );
      }

      // Check if OTP has expired
      if (_lastOtpSentAt != null) {
        final elapsed = DateTime.now().difference(_lastOtpSentAt!);
        if (elapsed > _otpExpiryDuration) {
          throw Exception('Code expiré. Veuillez demander un nouveau code.');
        }
      }

      if (_lastOtpCode != null) {
        if (enteredPhone != storedPhone) {
          throw Exception('Numéro de téléphone non correspondant');
        }
        if (smsCode != _lastOtpCode) {
          throw Exception('Code OTP invalide ou expiré');
        }
      } else if (!kDebugMode) {
        throw Exception('Code OTP invalide ou expiré');
      }

      await _completeSignIn(
        verificationId,
        isPhoneVerified: true,
      );

      // Clear OTP after successful verification
      _lastOtpCode = null;
      _lastOtpPhone = null;
      _lastOtpSentAt = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithoutOTP(String phoneNumber) async {
    if (!kDebugMode) {
      throw Exception('La vérification par SMS est obligatoire.');
    }
    _isLoading = true;
    notifyListeners();
    try {
      await _completeSignIn(phoneNumber, isPhoneVerified: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with phone number and password
  Future<void> signInWithPassword({
    required String phoneNumber,
    required String password,
    required Function onSuccess,
    required Function(dynamic e) onFailed,
  }) async {
    _isLoading = true;
    notifyListeners();

    final sw = Stopwatch()..start();
    try {
      final passwordHash = _hashPassword(password);

      // Check local database first, accepting common phone formats.
      final profile = await _repository.getCurrentUser();
      final localProfileMatches =
          profile != null && _isSamePhone(profile.phone, phoneNumber);
      if (localProfileMatches) {
        // Verify password without losing the stored hash on successful login.
        if (profile.passwordHash == passwordHash) {
          await _completeSignIn(
            profile.phone,
            isPhoneVerified: profile.isPhoneVerified,
            passwordHash: passwordHash,
            name: profile.name,
            avatarUrl: profile.avatarUrl,
            role: profile.role,
            skipRemoteProfileFetch: true,
          );
          onSuccess();
        } else if (profile.passwordHash == null ||
            profile.passwordHash!.isEmpty) {
          throw Exception(
            'Compte trouvé, mais aucun mot de passe n’est enregistré. Utilisez le code OTP ou recréez le mot de passe.',
          );
        } else {
          throw Exception('Mot de passe incorrect');
        }
      } else {
        // Check server for user using the dedicated login endpoint
        if (_syncService != null) {
          final loginResult = await _syncService!.api.loginWithPassword(
            phone: phoneNumber,
            passwordHash: passwordHash,
          );

          if (loginResult != null && loginResult['success'] == true) {
            // Login successful - user exists and password is correct
            final remoteProfile =
                loginResult['user'] as Map<String, dynamic>? ?? {};
            final remotePhone = remoteProfile['phone'] as String?;
            await _completeSignIn(
              remotePhone?.isNotEmpty == true ? remotePhone! : phoneNumber,
              isPhoneVerified: remoteProfile['is_phone_verified'] == true,
              passwordHash: passwordHash,
              name: remoteProfile['name']?.toString(),
              avatarUrl: remoteProfile['avatar_url']?.toString(),
              role: remoteProfile['role']?.toString() ?? 'user',
              skipRemoteProfileFetch: true,
            );
            onSuccess();
          } else if (loginResult != null && loginResult['error'] != null) {
            // Login failed - server returned an error
            throw Exception(loginResult['error']);
          } else {
            // No response from server
            throw Exception(
              'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
            );
          }
        } else {
          throw Exception('Impossible de vérifier les identifiants');
        }
      }
    } catch (e) {
      onFailed(e);
    } finally {
      if (kDebugMode) {
        debugPrint('PERF signInWithPassword: ${sw.elapsedMilliseconds}ms');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Hash a password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> _completeSignIn(
    String phone, {
    bool isPhoneVerified = false,
    String? passwordHash,
    String? name,
    String? avatarUrl,
    String? role,
    bool skipRemoteProfileFetch = false,
  }) async {
    final signInSw = Stopwatch()..start();
    final normalizedPhone = PhoneUtils.normalizeDrc(phone).isNotEmpty
        ? PhoneUtils.normalizeDrc(phone)
        : phone.trim();
    final String uid = normalizedPhone;
    String? existingName = name;
    String? existingAvatar = avatarUrl;
    _isPhoneVerified = isPhoneVerified;

    // Check for existing profile on server (skip when login already returned user).
    String userRole = role ?? 'user';
    if (!skipRemoteProfileFetch && _syncService != null) {
      final remoteProfile = await _syncService!.api.fetchUserByPhone(uid);
      if (remoteProfile != null) {
        existingName ??= remoteProfile['name']?.toString();
        existingAvatar ??= remoteProfile['avatar_url']?.toString();
        userRole = remoteProfile['role']?.toString() ?? userRole;
      }
    }

    _currentUser = MockUser(
      uid: uid,
      phoneNumber: normalizedPhone,
      displayName: existingName,
      photoURL: existingAvatar,
      role: userRole,
    );

    // Sync with local repository (upsert — preserves data across logins)
    final profile = UserProfile(
      id: 1, // Fixed ID for local session
      remoteId: uid,
      phone: normalizedPhone,
      name: existingName,
      avatarUrl: existingAvatar,
      passwordHash: passwordHash,
      isPhoneVerified: isPhoneVerified,
      role: userRole,
      createdAt: DateTime.now(),
    );
    await _repository.saveProfile(profile);

    // Reconnect any local shops whose ownerId matches this user's phone/uid.
    // This handles the case where a user logs back in after an app update
    // or logout — their shops should immediately be visible again.
    if (_shopRepository != null) {
      unawaited(() async {
        try {
          await _shopRepository!.reconnectShopsForUser(uid);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('AuthService: reconnectShopsForUser error: $e');
          }
        }
      }());
    }

    // Queue for remote sync (to ensure server has latest)
    if (_syncService != null) {
      final syncData = {
        'remote_id': uid,
        'phone': normalizedPhone,
        'name': existingName,
        'avatar_url': existingAvatar,
      };
      if (passwordHash != null) {
        syncData['password_hash'] = passwordHash;
      }
      await _syncService!.addToQueue('CREATE', 'users', syncData);
    }

    // Persist phone verification status
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('uza_phone_verified', _isPhoneVerified);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Failed to persist phone verification: $e');
      }
    }

    notifyListeners();
    if (kDebugMode) {
      debugPrint('PERF _completeSignIn: ${signInSw.elapsedMilliseconds}ms');
    }
  }

  /// Called from the unified shop creation flow.
  /// Creates/updates the user session without going through the OTP screen.
  Future<void> registerFromShopFlow(
    String phone, {
    bool isPhoneVerified = false,
    String? name,
    String? avatarUrl,
    String? password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final passwordHash = password != null ? _hashPassword(password) : null;
      await _completeSignIn(
        phone,
        isPhoneVerified: isPhoneVerified,
        passwordHash: passwordHash,
        name: name,
        avatarUrl: avatarUrl,
        skipRemoteProfileFetch: true,
      );
      if (name != null) {
        updateDisplayName(name);
      }
      if (avatarUrl != null) {
        updatePhotoUrl(avatarUrl);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reuses an OTP session from shop onboarding when the phone already matches.
  Future<void> ensureRegisteredFromShopFlow(
    String phone, {
    bool isPhoneVerified = false,
    String? name,
    String? avatarUrl,
    String? password,
  }) async {
    final normalizedPhone = PhoneUtils.normalizeDrc(phone).isNotEmpty
        ? PhoneUtils.normalizeDrc(phone)
        : phone.trim();
    if (_currentUser != null && _isSamePhone(_currentUser!.uid, normalizedPhone)) {
      final passwordHash = password != null ? _hashPassword(password) : null;
      if (name != null) {
        updateDisplayName(name);
      }
      if (avatarUrl != null) {
        updatePhotoUrl(avatarUrl);
      }
      await _repository.updateProfile(
        name: name,
        avatarUrl: avatarUrl,
        passwordHash: passwordHash,
      );
      if (_syncService != null &&
          (name != null || avatarUrl != null || passwordHash != null)) {
        await _syncService!.addToQueue('UPDATE', 'users', {
          'remote_id': normalizedPhone,
          'phone': normalizedPhone,
          if (name != null) 'name': name,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (passwordHash != null) 'password_hash': passwordHash,
        });
      }
      _isPhoneVerified = isPhoneVerified || _isPhoneVerified;
      notifyListeners();
      return;
    }
    await registerFromShopFlow(
      phone,
      isPhoneVerified: isPhoneVerified,
      name: name,
      avatarUrl: avatarUrl,
      password: password,
    );
  }

  /// Links local shops to the current user after shop creation.
  Future<void> refreshShopOwnership() async {
    final uid = _currentUser?.uid;
    if (uid == null || uid.isEmpty || _shopRepository == null) return;
    await _shopRepository!.reconnectShopsForUser(uid);
    notifyListeners();
  }

  void updatePhotoUrl(String? url) {
    if (_currentUser == null) return;
    _currentUser = MockUser(
      uid: _currentUser!.uid,
      phoneNumber: _currentUser!.phoneNumber,
      displayName: _currentUser!.displayName,
      photoURL: url,
      role: _currentUser!.role,
    );
    notifyListeners();
  }

  void updateDisplayName(String? name) {
    if (_currentUser == null) return;
    _currentUser = MockUser(
      uid: _currentUser!.uid,
      phoneNumber: _currentUser!.phoneNumber,
      displayName: name,
      photoURL: _currentUser!.photoURL,
      role: _currentUser!.role,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUser = null;
    _isPhoneVerified = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('uza_phone_verified');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Failed to clear phone verification: $e');
      }
    }
    await _repository.logout();
    notifyListeners();
  }
}
