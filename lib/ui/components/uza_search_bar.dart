import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';

enum UzaSearchBarVariant { compact, hero, inline }

class UzaSearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  final UzaSearchBarVariant variant;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  const UzaSearchBar({
    super.key,
    this.onTap,
    this.variant = UzaSearchBarVariant.compact,
    this.controller,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hint = tr(context, 'search_hint');

    if (variant == UzaSearchBarVariant.inline) {
      return TextField(
        controller: controller,
        autofocus: autofocus,
        readOnly: onTap != null,
        onTap: onTap,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: Icon(Icons.tune_rounded, color: scheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(UzaColors.radiusLg),
            borderSide: BorderSide.none,
          ),
        ),
      );
    }

    final height = variant == UzaSearchBarVariant.hero ? 48.0 : 40.0;
    final borderRadius = variant == UzaSearchBarVariant.hero ? 24.0 : 20.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: UzaColors.glassOverlay(context, alpha: 0.92),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.15),
            ),
            boxShadow: variant == UzaSearchBarVariant.hero
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.search_rounded,
                color: scheme.onSurface.withValues(alpha: 0.45),
                size: variant == UzaSearchBarVariant.hero ? 20 : 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.45),
                    fontSize: variant == UzaSearchBarVariant.hero ? 15 : 14,
                  ),
                ),
              ),
              Icon(
                Icons.tune_rounded,
                color: scheme.primary,
                size: variant == UzaSearchBarVariant.hero ? 20 : 18,
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
