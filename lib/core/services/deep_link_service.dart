import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import 'referral_service.dart';

/// Routes incoming native deep links into [GoRouter].
class DeepLinkService {
  DeepLinkService(this._router);

  final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial);
      }
      _subscription = _appLinks.uriLinkStream.listen(
        _handleUri,
        onError: (Object error) => debugPrint('DeepLinkService error: $error'),
      );
    } catch (e) {
      debugPrint('DeepLinkService init error: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _handleUri(Uri uri) {
    _captureReferral(uri);

    final path = mapUriToAppPath(uri);
    if (path == null) return;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _router.go(path);
    });
  }

  static void _captureReferral(Uri uri) {
    final ref = ReferralService.parseCodeFromUri(uri);
    if (ref != null) {
      unawaited(savePendingReferralCode(ref));
    }
  }

  /// Web / universal links on first load.
  static Future<void> captureReferralFromUri(Uri? uri) async {
    if (uri == null) return;
    final ref = ReferralService.parseCodeFromUri(uri);
    if (ref != null) await savePendingReferralCode(ref);
  }

  /// Maps https/uzaapp scheme URIs to GoRouter paths.
  static String? mapUriToAppPath(Uri uri) {
    if (uri.scheme == 'uzaapp') {
      final host = uri.host;
      final id = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : uri.path.replaceFirst('/', '');
      if ((host == 'product' || host == 'shop') &&
          id.isNotEmpty &&
          int.tryParse(id) != null) {
        return '/$host/$id';
      }
      return null;
    }

    if (uri.host == 'uzaapp.com' || uri.host == 'www.uzaapp.com') {
      final ref = uri.queryParameters['ref'] ?? uri.queryParameters['referral'];
      if (ref != null && ref.isNotEmpty && uri.pathSegments.isEmpty) {
        return '/';
      }
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final type = segments[0];
        final id = segments[1];
        if ((type == 'product' || type == 'shop') && int.tryParse(id) != null) {
          return '/$type/$id';
        }
      }
    }

    return null;
  }
}
