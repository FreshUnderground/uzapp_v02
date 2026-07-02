// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

class PwaInstallInfo {
  final bool shouldShow;
  final bool isIos;

  const PwaInstallInfo({
    required this.shouldShow,
    required this.isIos,
  });
}

class PwaInstallService {
  static PwaInstallInfo getInstallInfo() {
    if (_isStandalone()) {
      return const PwaInstallInfo(shouldShow: false, isIos: false);
    }
    final ios = _isIos();
    return PwaInstallInfo(shouldShow: true, isIos: ios);
  }

  static bool _isIos() {
    final ua = html.window.navigator.userAgent.toLowerCase();
    return ua.contains('iphone') ||
        ua.contains('ipad') ||
        ua.contains('ipod');
  }

  static bool _isStandalone() {
    if (html.window.matchMedia('(display-mode: standalone)').matches) {
      return true;
    }
    try {
      return (html.window.navigator as dynamic).standalone == true;
    } catch (_) {
      return false;
    }
  }
}
