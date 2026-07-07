import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import 'uza_back_button.dart';
import 'uza_toolbar_row.dart';

/// Persistent desktop navigation rail (≥1100px).
class DesktopShell extends StatelessWidget {
  final Widget child;
  final int? selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final List<Widget>? persistentActions;

  const DesktopShell({
    super.key,
    required this.child,
    this.selectedIndex,
    this.onDestinationSelected,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.persistentActions,
  });

  static const _destinations = [
    _Nav('/'),
    _Nav('/discover'),
    _Nav('/ya-cope'),
    _Nav('/shops'),
  ];

  static int? indexForPath(String path) {
    if (path == '/' || path.isEmpty) return 0;
    if (path.startsWith('/discover')) return 1;
    if (path.startsWith('/ya-cope')) return 2;
    if (path.startsWith('/shops')) return 3;
    return null;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (onDestinationSelected != null) {
      onDestinationSelected!(index);
      return;
    }
    context.go(_destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final railIndex = selectedIndex ?? indexForPath(GoRouterState.of(context).uri.path);

    return Row(
      children: [
        NavigationRail(
          extended: true,
          selectedIndex: railIndex ?? 0,
          onDestinationSelected: (i) => _onDestinationSelected(context, i),
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Image.asset('assets/logo.png', height: 60),
          ),
          destinations: [
            NavigationRailDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: Text(tr(context, 'home')),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore),
              label: Text(tr(context, 'discover')),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.recycling_outlined),
              selectedIcon: const Icon(Icons.recycling),
              label: Text(tr(context, 'ya_cope')),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: const Icon(Icons.storefront),
              label: Text(tr(context, 'boutiques')),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Scaffold(
            appBar: appBar,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
            body: Column(
              children: [
                if (persistentActions != null) ...persistentActions!,
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Nav {
  final String path;
  const _Nav(this.path);
}

/// Frosted app bar shared between mobile and desktop layouts.
class UzaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showLogo;
  final bool showBack;
  final String backFallback;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? bottom;
  final double height;

  const UzaAppBar({
    super.key,
    this.showLogo = true,
    this.showBack = false,
    this.backFallback = '/',
    this.title,
    this.titleWidget,
    this.actions,
    this.bottom,
    this.height = kToolbarHeight,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom != null ? 56.0 : 0.0;
    return Size.fromHeight(height + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final surface = UzaColors.glassOverlay(context, alpha: 0.85);

    Widget? leadingWidget;
    if (showBack) {
      leadingWidget = UzaBackButton(fallbackLocation: backFallback);
    } else if (showLogo) {
      leadingWidget = Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
      );
    }

    Widget? centerWidget = titleWidget;
    if (centerWidget == null && title != null) {
      centerWidget = Text(
        title!,
        style: const TextStyle(fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      );
    }

    return PreferredSize(
      preferredSize: preferredSize,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: height,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: UzaToolbarRow(
                      leading: leadingWidget,
                      center: centerWidget,
                      trailing: actions ?? const [],
                    ),
                  ),
                ),
                if (bottom != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: bottom!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
