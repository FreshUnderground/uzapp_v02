import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';

class UzaSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;
  final String? actionLabel;
  final double topPadding;
  final double bottomPadding;

  const UzaSectionHeader({
    super.key,
    required this.title,
    this.onAction,
    this.actionLabel,
    this.topPadding = 16,
    this.bottomPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: UzaColors.onSurface(context),
                  ),
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel ?? tr(context, 'see_all')),
            ),
        ],
      ),
    );
  }
}
