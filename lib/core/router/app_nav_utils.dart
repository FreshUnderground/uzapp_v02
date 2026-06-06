import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared bottom-tab navigation (Accueil, Découvrir, Boutiques, Profil).
class AppNavUtils {
  static const tabPaths = ['/', '/discover', '/shops', '/profile'];

  static bool _isFullScreenGoRoute(String path) {
    return path.startsWith('/shop/') ||
        path.startsWith('/product/') ||
        path == '/search' ||
        path == '/cart' ||
        path == '/orders' ||
        path == '/messages' ||
        path == '/b2b';
  }

  static void navigateToTab(BuildContext context, int index) {
    final safeIndex = index.clamp(0, tabPaths.length - 1);
    final target = tabPaths[safeIndex];
    final router = GoRouter.maybeOf(context);
    final shell = StatefulNavigationShell.maybeOf(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    // Deep-link GoRoutes (/shop/:id, /product/:id, …) — no GoRouterState on context
    if (router != null && _isFullScreenGoRoute(router.state.uri.path)) {
      router.go(target);
      return;
    }

    // Imperative Navigator.push overlays (SlideUpRoute, MaterialPageRoute, …)
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }

    if (shell != null) {
      shell.goBranch(
        safeIndex,
        initialLocation: safeIndex == shell.currentIndex,
      );
      return;
    }

    router?.go(target);
  }

  /// Active tab for overlay routes (shop/product detail → Boutiques).
  static int overlayTabIndex = 2;
}
