import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../../core/services/pwa_install_service.dart';

const _kDismissedKey = 'pwa_install_banner_dismissed';

/// Discrete banner on web to encourage installing the PWA.
class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> {
  bool _visible = false;
  bool _isIos = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!kIsWeb) return;

    final info = PwaInstallService.getInstallInfo();
    if (!info.shouldShow) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kDismissedKey) == true) return;

    if (!mounted) return;
    setState(() {
      _visible = true;
      _isIos = info.isIos;
    });
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDismissedKey, true);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_visible) return const SizedBox.shrink();

    final hintKey = _isIos ? 'pwa_install_hint_ios' : 'pwa_install_hint';

    return Material(
      color: UzaColors.secondary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.install_mobile, color: UzaColors.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(context, hintKey),
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: _dismiss,
              tooltip: tr(context, 'cancel'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
