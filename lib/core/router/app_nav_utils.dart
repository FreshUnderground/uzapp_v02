import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared bottom-tab navigation (Accueil, Découvrir, Boutiques, Profil).
class AppNavUtils {
  static const tabPaths = ['/', '/discover', '/ya-cope', '/shops'];

  static bool _isFullScreenGoRoute(String path) {
    return path.startsWith('/shop/') ||
        path.startsWith('/product/') ||
        path == '/search' ||
        path == '/cart' ||
        path == '/orders' ||
        path == '/messages' ||
        path == '/b2b';
  }

  /// Pops the current overlay route (Navigator.push, SlideUpRoute, GoRoute, …).
  static void popRoute(BuildContext context, {String fallback = '/'}) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator != navigator && rootNavigator.canPop()) {
      rootNavigator.pop();
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
      return;
    }

    router?.go(fallback);
  }

  static bool canPopRoute(BuildContext context) {
    if (Navigator.of(context).canPop()) return true;
    final root = Navigator.of(context, rootNavigator: true);
    if (root.canPop()) return true;
    return GoRouter.maybeOf(context)?.canPop() ?? false;
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
