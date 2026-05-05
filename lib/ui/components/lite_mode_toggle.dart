import 'package:flutter/material.dart';

class LiteModeToggle extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const LiteModeToggle({
    super.key,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Mode Léger'),
      subtitle: const Text('Masquer les images pour économiser les données'),
      value: isEnabled,
      onChanged: onChanged,
      secondary: const Icon(Icons.data_saver_on),
    );
  }
}
