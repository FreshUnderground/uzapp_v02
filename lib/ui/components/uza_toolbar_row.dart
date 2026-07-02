import 'package:flutter/material.dart';

/// Toolbar layout: leading control, flexible center, trailing actions.
class UzaToolbarRow extends StatelessWidget {
  final Widget? leading;
  final Widget? center;
  final List<Widget> trailing;
  final CrossAxisAlignment crossAxisAlignment;

  const UzaToolbarRow({
    super.key,
    this.leading,
    this.center,
    this.trailing = const [],
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (leading != null) leading!,
        Expanded(child: center ?? const SizedBox.shrink()),
        ...trailing,
      ],
    );
  }
}
