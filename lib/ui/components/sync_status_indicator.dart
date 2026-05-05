import 'package:flutter/material.dart';

class SyncStatusIndicator extends StatelessWidget {
  final DateTime? lastSyncTime;
  final VoidCallback? onTap;
  final bool showIcon;

  const SyncStatusIndicator({
    super.key,
    this.lastSyncTime,
    this.onTap,
    this.showIcon = true,
  });

  String _getTimeAgoText() {
    if (lastSyncTime == null) {
      return 'Jamais synchronisé';
    }

    final diff = DateTime.now().difference(lastSyncTime!);

    if (diff.inSeconds < 60) {
      return 'Mis à jour à l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Mis à jour il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Mis à jour il y a ${diff.inHours} h';
    } else {
      return 'Mis à jour il y a ${diff.inDays} j';
    }
  }

  Color _getIndicatorColor() {
    if (lastSyncTime == null) {
      return Colors.grey;
    }

    final diff = DateTime.now().difference(lastSyncTime!);

    if (diff.inMinutes < 5) {
      return Colors.green;
    } else if (diff.inMinutes < 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getIndicatorColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(Icons.sync, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              _getTimeAgoText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
