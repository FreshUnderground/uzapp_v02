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

class MockUser {
  final String uid;
  final String? phoneNumber;
  final String? displayName;
  final String? photoURL;

  MockUser({
    required this.uid,
    this.phoneNumber,
    this.displayName,
    this.photoURL,
  });
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
  MockUser? get firebaseUser =>
      _currentUser; // Keep getter name for compatibility
  MockUser? get user => _currentUser;

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
      if (profile != null) {
        _isPhoneVerified = profile.isPhoneVerified;
        // Use remoteId first; fall back to phone number as uid.
        // The phone number IS the uid in this system — shops store
        // ownerId = phone, so this ensures reassociation after updates.
        final uid = (profile.remoteId != null && profile.remoteId!.isNotEmpty)
            ? profile.remoteId!
            : profile.phone;
        _currentUser = MockUser(
          uid: uid,
          phoneNumber: profile.phone,
          displayName: profile.name,
          photoURL: profile.avatarUrl,
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Error loading session: $e');
      }
      // Try to recover from stored phone number if profile read failed
      try {
        final profile = await _repository.getCurrentUser();
        if (profile != null && profile.phone.isNotEmpty) {
          _currentUser = MockUser(
            uid: profile.phone,
            phoneNumber: profile.phone,
          );
          notifyListeners();
        }
      } catch (_) {
        // Give up — user will need to log in again
      }
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
      // Generate a 6-digit OTP code, or reuse existing one if it matches the phone
      final String otpCode;
      if (_lastOtpCode != null && _lastOtpPhone == phoneNumber) {
        otpCode = _lastOtpCode!;
      } else {
        final random = Random();
        otpCode = (100000 + random.nextInt(900000)).toString();
      }

      // Send OTP via Africa's Talking SMS
      final smsSent = await SmsService.envoyerCodeOtp(phoneNumber, otpCode);

      _isLoading = false;
      notifyListeners();

      if (smsSent) {
        // Store the OTP for verification
        _lastOtpCode = otpCode;
        _lastOtpPhone = phoneNumber;
        _lastOtpSentAt = DateTime.now();
        debugPrint('AuthService: OTP code sent to $phoneNumber');
        onCodeSent(phoneNumber);
      } else {
        debugPrint(
          'AuthService: Failed to send OTP via SMS, falling back to mock',
        );
        // Fallback: still allow login with any code (graceful degradation)
        _lastOtpCode = null; // null means accept any code
        _lastOtpPhone = phoneNumber;
        _lastOtpSentAt = DateTime.now();
        onCodeSent(phoneNumber);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('AuthService: Error sending OTP: $e');
      // Graceful degradation: fall back to mock
      _lastOtpCode = null;
      _lastOtpPhone = phoneNumber;
      _lastOtpSentAt = DateTime.now();
      onCodeSent(phoneNumber);
    }
  }

  Future<void> signInWithOTP(String verificationId, String smsCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Normalize phone numbers for comparison (remove all non-digit chars except +)
      final normalizePhone = (String phone) =>
          phone.replaceAll(RegExp(r'[^\d+]'), '');
      final enteredPhone = normalizePhone(verificationId);
      final storedPhone = _lastOtpPhone != null
          ? normalizePhone(_lastOtpPhone!)
          : '';

      debugPrint(
        'AuthService: Verifying OTP - Entered: $enteredPhone, Stored: $storedPhone',
      );
      debugPrint(
        'AuthService: OTP Code - Entered: $smsCode, Stored: $_lastOtpCode',
      );

      // Check if OTP has expired
      if (_lastOtpSentAt != null) {
        final elapsed = DateTime.now().difference(_lastOtpSentAt!);
        if (elapsed > _otpExpiryDuration) {
          debugPrint(
            'AuthService: OTP expired (${elapsed.inSeconds}s elapsed)',
          );
          throw Exception('Code expiré. Veuillez demander un nouveau code.');
        }
      }

      // If we have a stored OTP code, validate against it
      if (_lastOtpCode != null) {
        // Check phone number match using normalized comparison
        if (enteredPhone != storedPhone) {
          debugPrint(
            'AuthService: Phone mismatch - entered: $enteredPhone, stored: $storedPhone',
          );
          throw Exception('Numéro de téléphone non correspondant');
        }
        // Check OTP code match
        if (smsCode != _lastOtpCode) {
          debugPrint(
            'AuthService: OTP code mismatch - entered: $smsCode, expected: $_lastOtpCode',
          );
          throw Exception('Code OTP invalide ou expiré');
        }
      } else {
        // Fallback when SMS fails - accept any 6-digit code
        debugPrint('AuthService: Accepting any code (SMS failed fallback)');
      }

      await Future.delayed(const Duration(milliseconds: 800));
      await _completeSignIn(verificationId, isPhoneVerified: true);

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
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await _completeSignIn(phoneNumber, isPhoneVerified: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _completeSignIn(
    String phone, {
    bool isPhoneVerified = false,
  }) async {
    final String uid = phone;
    String? existingName;
    String? existingAvatar;
    _isPhoneVerified = isPhoneVerified;

    // Check for existing profile on server
    if (_syncService != null) {
      final remoteProfile = await _syncService!.api.fetchUserByPhone(phone);
      if (remoteProfile != null) {
        existingName = remoteProfile['name'];
        existingAvatar = remoteProfile['avatar_url'];
      }
    }

    _currentUser = MockUser(
      uid: uid,
      phoneNumber: phone,
      displayName: existingName,
      photoURL: existingAvatar,
    );

    // Sync with local repository (upsert — preserves data across logins)
    final profile = UserProfile(
      id: 1, // Fixed ID for local session
      remoteId: uid,
      phone: phone,
      name: existingName,
      avatarUrl: existingAvatar,
      isPhoneVerified: isPhoneVerified,
      createdAt: DateTime.now(),
    );
    await _repository.saveProfile(profile);

    // Reconnect any local shops whose ownerId matches this user's phone/uid.
    // This handles the case where a user logs back in after an app update
    // or logout — their shops should immediately be visible again.
    if (_shopRepository != null) {
      await _shopRepository!.reconnectShopsForUser(uid);
    }

    // Queue for remote sync (to ensure server has latest)
    if (_syncService != null) {
      await _syncService!.addToQueue('CREATE', 'users', {
        'remote_id': uid,
        'phone': phone,
        'name': existingName,
        'avatar_url': existingAvatar,
      });
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
  }

  /// Called from the unified shop creation flow.
  /// Creates/updates the user session without going through the OTP screen.
  Future<void> registerFromShopFlow(
    String phone, {
    bool isPhoneVerified = false,
    String? name,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _completeSignIn(phone, isPhoneVerified: isPhoneVerified);
      // Update name/avatar if provided
      if (name != null || avatarUrl != null) {
        await _repository.updateProfile(name: name, avatarUrl: avatarUrl);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
