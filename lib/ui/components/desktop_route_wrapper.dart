import 'package:flutter/material.dart';
import '../components/desktop_shell.dart';
import '../components/responsive_layout.dart';
import '../components/sync_status_banner.dart';

/// Wraps secondary routes with [DesktopShell] on wide screens.
class DesktopRouteWrapper extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const DesktopRouteWrapper({
    super.key,
    required this.child,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Scaffold(
        appBar: appBar,
        body: Column(
          children: [
            const SyncStatusBanner(),
            Expanded(child: child),
          ],
        ),
      ),
      desktop: DesktopShell(
        appBar: appBar,
        child: Column(
          children: [
            const SyncStatusBanner(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
