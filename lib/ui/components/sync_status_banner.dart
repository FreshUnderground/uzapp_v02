import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/tr.dart';
import '../../data/services/sync_service.dart';

/// Compact banner shown under the app bar when offline or sync failed.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        if (syncService.syncStatus == SyncStatus.offline) {
          return _Banner(
            icon: Icons.wifi_off,
            color: Colors.orange,
            label: tr(context, 'offline'),
          );
        }
        if (syncService.syncStatus == SyncStatus.error) {
          return _Banner(
            icon: Icons.sync_problem,
            color: Colors.red.shade700,
            label: tr(context, 'sync_error'),
            onTap: () => syncService.syncNow(),
            trailing: Text(
              tr(context, 'retry'),
              style: TextStyle(
                fontSize: 11,
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _Banner({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );

    return Material(
      color: color.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: content,
        ),
      ),
    );
  }
}
