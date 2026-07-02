import 'package:flutter/material.dart';

/// Desktop profile layout: header column + scrollable content.
class ProfileDesktopLayout extends StatelessWidget {
  final Widget header;
  final Widget content;

  const ProfileDesktopLayout({
    super.key,
    required this.header,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 360, child: header),
          const SizedBox(width: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, right: 24),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}
