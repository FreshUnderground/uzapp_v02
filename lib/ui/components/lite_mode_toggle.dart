import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';

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
      title: Text(tr(context, 'lite_mode')),
      subtitle: Text(tr(context, 'lite_mode_subtitle')),
      value: isEnabled,
      onChanged: onChanged,
      secondary: const Icon(Icons.data_saver_on),
    );
  }
}
