import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/tr.dart';
import '../../data/services/sync_service.dart';

/// Debug screen to diagnose sync issues
class SyncDebugScreen extends StatelessWidget {
  const SyncDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = context.watch<SyncService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'sync_diagnostics')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(syncService),
            const SizedBox(height: 16),

            // Actions
            _buildActions(context, syncService),
            const SizedBox(height: 16),

            // Info
            _buildInfoSection(syncService),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(SyncService syncService) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (syncService.syncStatus) {
      case SyncStatus.idle:
        statusColor = Colors.green;
        statusText = 'Idle';
        statusIcon = Icons.check_circle;
        break;
      case SyncStatus.syncing:
        statusColor = Colors.blue;
        statusText = 'Syncing...';
        statusIcon = Icons.sync;
        break;
      case SyncStatus.error:
        statusColor = Colors.red;
        statusText = 'Error';
        statusIcon = Icons.error;
        break;
      case SyncStatus.offline:
        statusColor = Colors.orange;
        statusText = 'Offline';
        statusIcon = Icons.wifi_off;
        break;
    }

    return Card(
      color: statusColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(statusIcon, size: 48, color: statusColor),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            if (syncService.lastSyncTime != null)
              Text(
                'Last sync: ${syncService.lastSyncTime}',
                style: const TextStyle(fontSize: 14),
              ),
            if (syncService.pendingChangesCount > 0)
              Text(
                'Pending changes: ${syncService.pendingChangesCount}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, SyncService syncService) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: syncService.isSyncing ? null : () => syncService.syncNow(),
          icon: const Icon(Icons.sync),
          label: Text(tr(context, 'manual_sync')),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: syncService.isSyncing
              ? null
              : () => syncService.forcePush(),
          icon: const Icon(Icons.cloud_upload),
          label: Text(tr(context, 'force_push_all')),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: syncService.isSyncing
              ? null
              : () => syncService.fullResetAndSync(),
          icon: const Icon(Icons.refresh),
          label: Text(tr(context, 'full_reset_sync')),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final status = await syncService.getQueueStatus();
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(tr(ctx, 'queue_status')),
                  content: SingleChildScrollView(
                    child: Text(
                      'Total: ${status['total']}\n'
                      'By Type: ${status['byEntityType']}\n'
                      'By Action: ${status['byAction']}',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(tr(ctx, 'close')),
                    ),
                  ],
                ),
              );
            }
          },
          icon: const Icon(Icons.info),
          label: Text(tr(context, 'view_queue_details')),
        ),
      ],
    );
  }

  Widget _buildInfoSection(SyncService syncService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sync Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Is Syncing', syncService.isSyncing.toString()),
            _buildInfoRow(
              'Pending Changes',
              syncService.pendingChangesCount.toString(),
            ),
            _buildInfoRow('First Sync', syncService.isFirstSync.toString()),
            _buildInfoRow(
              'Last Sync',
              syncService.lastSyncTime?.toString() ?? 'Never',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}
