import 'package:flutter/material.dart';
import '../../data/repositories/shop_repository.dart';
import 'package:provider/provider.dart';

class AnalyticsTab extends StatelessWidget {
  final int shopId;
  const AnalyticsTab({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    final shopRepo = context.read<ShopRepository>();

    return FutureBuilder<Map<String, int>>(
      future: shopRepo.getShopStats(shopId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snapshot.data ?? {};

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Performance de votre Boutique',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Suivez l\'engagement de vos clients en temps réel.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Interaction Summary
            _buildSectionTitle('Engagement Total'),
            const SizedBox(height: 16),
            _buildInteractionSummary(stats),

            const SizedBox(height: 32),
            _buildSectionTitle('Détails des Contacts'),
            const SizedBox(height: 16),
            _buildDetailedStats(stats),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInteractionSummary(Map<String, int> stats) {
    final totalViews =
        (stats['view'] ?? 0) + (stats['product_view_global'] ?? 0);
    final totalContacts =
        (stats['contact_whatsapp'] ?? 0) +
        (stats['contact_call'] ?? 0) +
        (stats['contact_sms'] ?? 0);

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Total Vues',
            '$totalViews',
            Icons.remove_red_eye,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCard(
            'Total Contacts',
            '$totalContacts',
            Icons.message,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(Map<String, int> stats) {
    return Column(
      children: [
        _detailedRow(
          'Vues Boutique',
          stats['view'] ?? 0,
          Icons.storefront,
          Colors.blue,
        ),
        _detailedRow(
          'Vues Produits (Global)',
          stats['product_view_global'] ?? 0,
          Icons.visibility,
          Colors.purple,
        ),
        _detailedRow(
          'Partages Produits (Global)',
          stats['product_share_global'] ?? 0,
          Icons.share,
          Colors.orange,
        ),
        _detailedRow(
          'Contacts WhatsApp',
          stats['contact_whatsapp'] ?? 0,
          Icons.chat,
          Colors.green,
        ),
        _detailedRow(
          'Appels Directs',
          stats['contact_call'] ?? 0,
          Icons.phone,
          Colors.blueGrey,
        ),
        _detailedRow(
          'SMS envoyés',
          stats['contact_sms'] ?? 0,
          Icons.sms,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _detailedRow(String label, int value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
