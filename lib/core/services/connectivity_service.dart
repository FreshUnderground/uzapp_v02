import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';

enum ConnectivityType { wifi, mobile, none }

/// Monitors network connectivity using simple HTTP HEAD requests
/// without requiring external packages like connectivity_plus.
class ConnectivityService extends ChangeNotifier {
  ConnectivityType _type = ConnectivityType.none;
  bool _isOnline = false;
  Timer? _monitorTimer;

  ConnectivityType get type => _type;
  bool get isOnline => _isOnline;

  /// The URL to ping for connectivity checks.
  /// Uses ping.php which requires no authentication.
  static const String _healthCheckUrl = 'https://uzaapp.com/api/ping.php';

  /// Initialize and start periodic connectivity monitoring.
  Future<void> initialize() async {
    await checkConnectivity();
    // Check every 30 seconds
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

  /// Web-based connectivity check using dart:html or a simple approach.
  /// On web, we can't use dart:io, so we skip the check
  /// and assume online (browsers handle connectivity differently).
  Future<void> _checkConnectivityWeb() async {
    // On web, we assume online since the browser manages connectivity.
    // A more robust approach would use dart:html's HttpRequest,
    // but that adds web-specific imports.
    final wasOnline = _isOnline;
    _isOnline = true;
    _type = ConnectivityType.mobile;

    if (!wasOnline) {
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
