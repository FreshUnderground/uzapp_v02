import 'package:flutter/material.dart';

import 'uza_back_button.dart';
import 'uza_toolbar_row.dart';

/// Top overlay for immersive media screens (Discover, stories, etc.).
class UzaMediaTopBar extends StatelessWidget {
  final List<Widget> actions;
  final String fallbackLocation;
  final bool showBack;
  final bool onDarkBackground;

  const UzaMediaTopBar({
    super.key,
    required this.actions,
    this.fallbackLocation = '/',
    this.showBack = true,
    this.onDarkBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: UzaToolbarRow(
          leading: showBack
              ? UzaBackButton(
                  fallbackLocation: fallbackLocation,
                  onDarkBackground: onDarkBackground,
                )
              : const SizedBox(width: 8),
          trailing: actions,
        ),
      ),
    );
  }
}
