import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/sync_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/local/uza_database.dart';

/// Debug screen to diagnose shop sync issues
class ShopSyncDebugScreen extends StatefulWidget {
  const ShopSyncDebugScreen({Key? key}) : super(key: key);

  @override
  State<ShopSyncDebugScreen> createState() => _ShopSyncDebugScreenState();
}

class _ShopSyncDebugScreenState extends State<ShopSyncDebugScreen> {
  List<Shop> _localShops = [];
  List<Map<String, dynamic>> _syncQueue = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final shopRepo = context.read<ShopRepository>();
      final syncService = context.read<SyncService>();

      // Load local shops
      _localShops = await shopRepo.watchAllShops().first;

      // Load sync queue
      final queue = await syncService.getQueueStatus();
      _syncQueue = List<Map<String, dynamic>>.from(queue['items'] ?? []);
    } catch (e) {
      debugPrint('Error loading debug data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Sync Debug'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildLocalShopsCard(),
                  const SizedBox(height: 16),
                  _buildSyncQueueCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final shopCount = _localShops.length;
    final queueCount = _syncQueue.length;
    final shopQueueItems = _syncQueue
        .where((item) => item['entityType'] == 'shops')
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Local Shops', '$shopCount', Icons.store),
            _buildSummaryRow('Sync Queue Items', '$queueCount', Icons.sync),
            _buildSummaryRow(
              'Shop Sync Items',
              '$shopQueueItems',
              Icons.cloud_upload,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalShopsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Local Shops (SQLite)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_localShops.isEmpty)
              const Text(
                'No shops found locally',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._localShops.map((shop) => _buildShopTile(shop)),
          ],
        ),
      ),
    );
  }

  Widget _buildShopTile(Shop shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shop.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          if (shop.ownerId != null)
            Text(
              'Owner ID: ${shop.ownerId}',
              style: const TextStyle(fontSize: 12),
            ),
          if (shop.phone != null)
            Text('Phone: ${shop.phone}', style: const TextStyle(fontSize: 12)),
          Text('Type: ${shop.type.name}', style: const TextStyle(fontSize: 12)),
          Text('ID: ${shop.id}', style: const TextStyle(fontSize: 12)),
          if (shop.remoteId != null)
            Text(
              'Remote ID: ${shop.remoteId}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildSyncQueueCard() {
    final shopQueueItems = _syncQueue
        .where((item) => item['entityType'] == 'shops')
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sync Queue (Shops)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (shopQueueItems.isEmpty)
              const Text(
                'No shop items in sync queue',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...shopQueueItems.map((item) => _buildQueueTile(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTile(Map<String, dynamic> item) {
    final data = jsonDecode(item['entityData'] ?? '{}') as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '${item['action']} - ${item['entityType']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'Retries: ${item['retries']}',
                style: TextStyle(
                  fontSize: 12,
                  color: (item['retries'] ?? 0) > 2 ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Shop Name: ${data['name'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Owner ID: ${data['owner_id'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Type: ${data['type'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SyncService>().forcePush();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Force push triggered')),
                );
              },
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Force Push All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SyncService>().syncNow();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Manual sync triggered')),
                );
              },
              icon: const Icon(Icons.sync),
              label: const Text('Manual Sync'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                context.read<SyncService>().clearQueue();
                setState(() => _syncQueue.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync queue cleared')),
                );
              },
              icon: const Icon(Icons.delete),
              label: const Text('Clear Sync Queue'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
