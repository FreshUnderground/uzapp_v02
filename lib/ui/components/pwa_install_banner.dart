import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';

/// Shown on web to encourage installing the PWA or using the mobile app.
class PwaInstallBanner extends StatelessWidget {
  final VoidCallback? onDismiss;

  const PwaInstallBanner({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    return Material(
      color: UzaColors.secondary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.install_mobile, color: UzaColors.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(context, 'pwa_install_hint'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onDismiss,
                tooltip: tr(context, 'cancel'),
              ),
          ],
        ),
      ),
    );
  }
}
