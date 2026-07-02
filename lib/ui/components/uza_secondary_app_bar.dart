import 'package:flutter/material.dart';

import '../../core/router/app_nav_utils.dart';
import 'uza_back_button.dart';
import 'uza_toolbar_row.dart';

/// App bar with a reliable back action for pushed / secondary routes.
class UzaSecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final String fallbackLocation;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const UzaSecondaryAppBar({
    super.key,
    required this.title,
    this.actions,
    this.fallbackLocation = '/',
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      elevation: elevation,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      titleSpacing: 0,
      title: UzaToolbarRow(
        leading: UzaBackButton(fallbackLocation: fallbackLocation),
        center: centerTitle
            ? Center(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
        trailing: actions ?? const [],
      ),
    );
  }
}

/// Handles Android/iOS system back on secondary routes.
class UzaBackScope extends StatelessWidget {
  final String fallbackLocation;
  final Widget child;

  const UzaBackScope({
    super.key,
    required this.child,
    this.fallbackLocation = '/',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        AppNavUtils.popRoute(context, fallback: fallbackLocation);
      },
      child: child,
    );
  }
}
