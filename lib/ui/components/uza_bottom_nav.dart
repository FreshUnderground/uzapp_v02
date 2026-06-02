import 'package:flutter/material.dart';
import 'animated_bottom_nav.dart';

/// @deprecated Use [AnimatedBottomNav] directly. Kept for backward compatibility.
class UzaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const UzaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNav(currentIndex: currentIndex, onTap: onTap);
  }
}
