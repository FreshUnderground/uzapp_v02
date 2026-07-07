import 'package:flutter/material.dart';
import '../components/desktop_shell.dart';
import '../components/responsive_layout.dart';

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
        body: child,
      ),
      desktop: DesktopShell(
        appBar: appBar,
        child: child,
      ),
    );
  }
}
