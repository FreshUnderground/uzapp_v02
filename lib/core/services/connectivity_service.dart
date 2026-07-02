import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'connectivity/browser_online.dart';

enum ConnectivityType { wifi, mobile, none }

/// Monitors network connectivity using simple HTTP HEAD requests
/// without requiring external packages like connectivity_plus.
class ConnectivityService extends ChangeNotifier {
  ConnectivityType _type = ConnectivityType.none;
  bool _isOnline = false;
  Timer? _monitorTimer;

  ConnectivityService() {
    // Assume online on web when the browser reports connectivity so sync
    // is not blocked while the ping health-check is in flight.
    if (kIsWeb && getBrowserOnline()) {
      _isOnline = true;
      _type = ConnectivityType.mobile;
    }
  }

  ConnectivityType get type => _type;
  bool get isOnline => _isOnline;

  /// The URL to ping for connectivity checks.
  /// Uses ping.php which requires no authentication.
  static const String _healthCheckUrl = 'https://uzaapp.com/api/ping.php';

  /// Initialize and start periodic connectivity monitoring.
  Future<void> initialize() async {
    if (kIsWeb) {
      listenBrowserConnectivity((online) {
        if (!online) {
          setConnectivity(online: false);
        } else {
          checkConnectivity();
        }
      });
    }
    await checkConnectivity();
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => checkConnectivity(),
    );
  }

  /// Perform a single connectivity check by issuing an HTTP HEAD request.
  Future<void> checkConnectivity() async {
    // On web platform, skip the dart:io connectivity check
    // and rely on the HTTP client's behavior instead.
    if (kIsWeb) {
      await _checkConnectivityWeb();
      return;
    }

    try {
      final client = io.HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.headUrl(Uri.parse(_healthCheckUrl));
      final response = await request.close();

      final wasOnline = _isOnline;
      // Any 2xx or 3xx response means we're online
      final isReachable =
          response.statusCode >= 200 && response.statusCode < 400;

      _isOnline = isReachable;
      _type = isReachable ? ConnectivityType.mobile : ConnectivityType.none;

      client.close(force: true);

      if (wasOnline != _isOnline) {
        debugPrint(
          'ConnectivityService: connectivity changed to ${_isOnline ? "online" : "offline"}',
        );
        notifyListeners();
      }
    } catch (e) {
      final wasOnline = _isOnline;
      _isOnline = false;
      _type = ConnectivityType.none;

      if (wasOnline) {
        debugPrint('ConnectivityService: connectivity lost - $e');
        notifyListeners();
      }
    }
  }

  /// Web: navigator.onLine + ping API when browser reports online.
  Future<void> _checkConnectivityWeb() async {
    final wasOnline = _isOnline;
    if (!getBrowserOnline()) {
      _isOnline = false;
      _type = ConnectivityType.none;
      if (wasOnline != _isOnline) notifyListeners();
      return;
    }
    try {
      final response = await http
          .head(Uri.parse(_healthCheckUrl))
          .timeout(const Duration(seconds: 5));
      final reachable =
          response.statusCode >= 200 && response.statusCode < 400;
      _isOnline = reachable;
      _type = reachable ? ConnectivityType.mobile : ConnectivityType.none;
    } catch (_) {
      _isOnline = false;
      _type = ConnectivityType.none;
    }
    if (wasOnline != _isOnline) {
      debugPrint(
        'ConnectivityService (web): ${_isOnline ? "online" : "offline"}',
      );
      notifyListeners();
    }
  }

  /// Manually set connectivity state (useful for testing or
  /// when connectivity info is received from another source).
  void setConnectivity({required bool online, ConnectivityType? type}) {
    final wasOnline = _isOnline;
    _isOnline = online;
    _type = type ?? (online ? ConnectivityType.mobile : ConnectivityType.none);

    if (wasOnline != _isOnline) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }
}
