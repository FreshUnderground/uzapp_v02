import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import 'referral_service.dart';

/// Routes incoming native deep links into [GoRouter].
class DeepLinkService {
  DeepLinkService(this._router);

  final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;

  /// Path for the cold-start link, read before [runApp] when possible.
  static String? launchPath;

  /// Call from [main] before [runApp] so App Links are not lost during DB init.
  static Future<void> captureLaunchUri() async {
    if (kIsWeb) {
      final path = Uri.base.path;
      if (AppRouter.isRoutableLaunchPath(path)) {
        launchPath = path;
      }
      await captureReferralFromUri(Uri.base);
      return;
    }

    try {
      final initial = await AppLinks().getInitialLink();
      if (initial == null) return;
      _captureReferral(initial);
      launchPath = mapUriToAppPath(initial);
      if (launchPath != null) {
        debugPrint('DeepLinkService launch path: $launchPath ($initial)');
      }
    } catch (e) {
      debugPrint('DeepLinkService.captureLaunchUri error: $e');
    }
  }

  /// Consumes [launchPath] for GoRouter [initialLocation].
  static String? consumeLaunchPath() {
    final path = launchPath;
    launchPath = null;
    return path;
  }

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        final path = mapUriToAppPath(initial);
        if (path != null && _router.state.uri.path != path) {
          _handleUri(initial);
        }
      } else if (launchPath != null) {
        _goPath(launchPath!);
        launchPath = null;
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
    _goPath(path);
  }

  void _goPath(String path) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_router.state.uri.path != path) {
        _router.go(path);
      }
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
      if (host == 'product' || host == 'shop' || host == 'ya-cope') {
        final id = _firstIdSegment(uri);
        if (id != null) {
          if (host == 'ya-cope') return '/ya-cope/$id';
          return '/$host/$id';
        }
      }

      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length >= 2) {
        final type = segments[0];
        final id = segments[1];
        if (int.tryParse(id) != null) {
          if (type == 'product' || type == 'shop') return '/$type/$id';
          if (type == 'ya-cope') return '/ya-cope/$id';
        }
      }
      return null;
    }

    if (uri.host == 'uzaapp.com' || uri.host == 'www.uzaapp.com') {
      final ref = uri.queryParameters['ref'] ?? uri.queryParameters['referral'];
      if (ref != null && ref.isNotEmpty && uri.pathSegments.isEmpty) {
        return '/';
      }
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length >= 2) {
        final type = segments[0];
        final id = segments[1];
        if (int.tryParse(id) != null) {
          if (type == 'product' || type == 'shop') return '/$type/$id';
          if (type == 'ya-cope') return '/ya-cope/$id';
        }
      }
    }

    return null;
  }

  static String? _firstIdSegment(Uri uri) {
    if (uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.firstWhere(
        (s) => s.isNotEmpty,
        orElse: () => '',
      );
      if (id.isNotEmpty && int.tryParse(id) != null) return id;
    }
    final trimmed = uri.path.replaceFirst('/', '').trim();
    if (trimmed.isNotEmpty && int.tryParse(trimmed) != null) return trimmed;
    return null;
  }
}
