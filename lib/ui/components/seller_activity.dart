import 'package:flutter/material.dart';

/// Shows a seller's responsiveness based on their average response time.
///
/// Displays a colored dot + French label:
/// - < 30 min  → green  "Répond rapidement"
/// - < 2 h     → orange "Répond en ~Xmin"
/// - < 24 h    → red    "Répond en ~Xh"
/// - ≥ 24 h    → grey   "Temps de réponse long"
///
/// Returns an empty [SizedBox] when [responseTimeMinutes] is null.
class SellerActivityIndicator extends StatelessWidget {
  final int? responseTimeMinutes;

  const SellerActivityIndicator({super.key, this.responseTimeMinutes});

  @override
  Widget build(BuildContext context) {
    if (responseTimeMinutes == null) return const SizedBox.shrink();

    final (label, color) = _getActivityInfo(responseTimeMinutes!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  (String, Color) _getActivityInfo(int minutes) {
    if (minutes < 30) {
      return ('Répond rapidement', const Color(0xFF4CAF50));
    }
    if (minutes < 120) {
      return ('Répond en ~${minutes}min', const Color(0xFFFF9800));
    }
    if (minutes < 1440) {
      return ('Répond en ~${(minutes / 60).round()}h', const Color(0xFFF44336));
    }
    return ('Temps de réponse long', const Color(0xFF9E9E9E));
  }
}
