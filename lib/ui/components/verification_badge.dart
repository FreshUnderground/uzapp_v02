import 'package:flutter/material.dart';

/// A small circular check-mark badge indicating a verified seller/shop.
///
/// Returns an empty [SizedBox] when [isVerified] is false, so it can be
/// placed inline without conditional logic in the parent widget.
class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Color(0xFF019C94), // UZA teal
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, size: size, color: Colors.white),
    );
  }
}
