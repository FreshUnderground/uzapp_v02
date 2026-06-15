import 'package:flutter/material.dart';
import '../../core/res/uza_colors.dart';
import '../../data/repositories/shop_repository.dart';
import 'package:provider/provider.dart';

class AnalyticsTab extends StatelessWidget {
  final int shopId;
  const AnalyticsTab({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    final shopRepo = context.read<ShopRepository>();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        shopRepo.getShopStats(shopId),
        shopRepo.getWeeklyStats(shopId),
        shopRepo.getDailyViewsBreakdown(shopId),
        shopRepo.getTopViewedProducts(shopId),
        shopRepo.getConversionMetrics(shopId),
        shopRepo.getBestPublishTimes(shopId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = (snapshot.data?[0] as Map<String, int>?) ?? {};
        final weekly = (snapshot.data?[1] as Map<String, int>?) ?? {};
        final dailyViews = (snapshot.data?[2] as List<int>?) ?? List.filled(7, 0);
        final topProducts =
            (snapshot.data?[3] as List<Map<String, dynamic>>?) ?? [];
        final conversion =
            (snapshot.data?[4] as Map<String, dynamic>?) ?? {};
        final publishTimes =
            (snapshot.data?[5] as Map<String, dynamic>?) ?? {};

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Performance de votre Boutique',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Suivez l\'engagement de vos clients en temps réel.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('7 derniers jours'),
            const SizedBox(height: 16),
            _buildWeeklyKpiRow(weekly),
            const SizedBox(height: 16),
            _buildViewsChart(context, dailyViews),
            const SizedBox(height: 32),

            _buildSectionTitle('Engagement Total'),
            const SizedBox(height: 16),
            _buildEngagementSummary(stats),
            const SizedBox(height: 32),

            _buildSectionTitle('Conversion'),
            const SizedBox(height: 16),
            _buildConversionRow(conversion),
            const SizedBox(height: 32),

            _buildSectionTitle('Meilleur moment pour publier'),
            const SizedBox(height: 16),
            _buildPublishInsight(publishTimes),
            const SizedBox(height: 32),

            _buildSectionTitle('Produits les plus vus'),
            const SizedBox(height: 16),
            _buildTopProducts(topProducts),
            const SizedBox(height: 32),

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

  Widget _buildWeeklyKpiRow(Map<String, int> weekly) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Vues (7j)',
            '${weekly['weeklyViews'] ?? 0}',
            Icons.visibility,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'Contacts (7j)',
            '${weekly['weeklyContacts'] ?? 0}',
            Icons.chat,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            'Partages (7j)',
            '${weekly['weeklyShares'] ?? 0}',
            Icons.share,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildViewsChart(BuildContext context, List<int> dailyViews) {
    final maxVal = dailyViews.reduce((a, b) => a > b ? a : b);
    final labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final startDay = DateTime.now().subtract(const Duration(days: 6)).weekday;
    final dayLabels = List.generate(7, (i) {
      final day = (startDay + i - 1) % 7;
      return labels[day];
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final val = dailyViews[i];
          final heightFactor = maxVal > 0 ? val / maxVal : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$val', style: const TextStyle(fontSize: 10)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: heightFactor.clamp(0.05, 1.0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: UzaColors.primary.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(dayLabels[i], style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          );
        }),
      ),
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
          UzaColors.secondary,
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

  Widget _buildConversionRow(Map<String, dynamic> data) {
    String pct(dynamic v) => '${(v as num?)?.toStringAsFixed(1) ?? '0.0'}%';
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Vue → WhatsApp',
                pct(data['viewToContact']),
                Icons.trending_up,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                'WhatsApp → Cmd',
                pct(data['contactToOrder']),
                Icons.shopping_bag_outlined,
                Colors.deepOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _detailedRow(
          'Vues totales',
          data['views'] as int? ?? 0,
          Icons.visibility,
          Colors.blue,
        ),
        _detailedRow(
          'Contacts WhatsApp',
          data['whatsapp'] as int? ?? 0,
          Icons.chat,
          Colors.green,
        ),
        _detailedRow(
          'Commandes',
          data['orders'] as int? ?? 0,
          Icons.receipt_long,
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildPublishInsight(Map<String, dynamic> data) {
    final hour = data['bestHour'] as int? ?? 18;
    final day = data['bestDay'] as String? ?? 'Vendredi';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UzaColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UzaColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: UzaColors.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publiez vers ${hour}h00',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Jour le plus actif : $day',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return Text(
        'Pas encore de données de vues produits.',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }
    return Column(
      children: products.map((p) {
        return _detailedRow(
          p['name'] as String? ?? 'Produit',
          p['views'] as int? ?? 0,
          Icons.remove_red_eye_outlined,
          Colors.blueGrey,
        );
      }).toList(),
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
