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

            // Engagement Summary Cards (top row)
            _buildSectionTitle('Engagement Total'),
            const SizedBox(height: 16),
            _buildEngagementSummary(stats),
            const SizedBox(height: 32),

            // Detailed Metrics
            _buildSectionTitle('Détails des Statistiques'),
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

  Widget _buildEngagementSummary(Map<String, int> stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 160,
          child: _summaryCard(
            'Suivi',
            '${stats['totalFollowers'] ?? 0}',
            Icons.people,
            Colors.purple,
          ),
        ),
        SizedBox(
          width: 160,
          child: _summaryCard(
            'Likes',
            '${stats['totalLikes'] ?? 0}',
            Icons.favorite,
            Colors.red,
          ),
        ),
        SizedBox(
          width: 160,
          child: _summaryCard(
            'Total Vues',
            '${stats['totalViews'] ?? 0}',
            Icons.remove_red_eye,
            Colors.blue,
          ),
        ),
        SizedBox(
          width: 160,
          child: _summaryCard(
            'Total Contacts',
            '${stats['totalContacts'] ?? 0}',
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
        // Engagement section
        _detailedRow(
          'Suivi (Followers)',
          stats['totalFollowers'] ?? 0,
          Icons.people,
          Colors.purple,
        ),
        _detailedRow(
          'Likes (Produits)',
          stats['totalLikes'] ?? 0,
          Icons.favorite,
          Colors.red,
        ),
        _detailedRow(
          'Partages',
          stats['totalShares'] ?? 0,
          Icons.share,
          Colors.orange,
        ),
        const Divider(height: 32),

        // Views section
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
          Colors.indigo,
        ),
        const Divider(height: 32),

        // Contacts section
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
        const Divider(height: 32),

        // Client section
        _detailedRow(
          'Clients Uniques',
          stats['uniqueClients'] ?? 0,
          Icons.person,
          Colors.deepPurple,
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
