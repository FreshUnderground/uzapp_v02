import 'package:flutter/material.dart';

import '../../core/l10n/tr.dart';
import '../../core/router/app_nav_utils.dart';

/// Consistent back control for pushed routes, GoRouter pages, and overlays.
class UzaBackButton extends StatelessWidget {
  final String fallbackLocation;
  final Color? color;
  final bool onDarkBackground;

  const UzaBackButton({
    super.key,
    this.fallbackLocation = '/',
    this.color,
    this.onDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? (onDarkBackground ? Colors.white : null);

    return IconButton(
      icon: Icon(Icons.arrow_back, color: iconColor),
      tooltip: tr(context, 'back'),
      onPressed: () => AppNavUtils.popRoute(
        context,
        fallback: fallbackLocation,
      ),
    );
  }
}
