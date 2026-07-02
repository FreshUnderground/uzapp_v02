import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/res/uza_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/auth_service.dart';
import 'admin_moderation_panel.dart';

class AdminDashboardTab extends StatefulWidget {
  final VoidCallback? onOpenModeration;

  const AdminDashboardTab({super.key, this.onOpenModeration});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  String _preset = '30d';
  Future<Map<String, dynamic>?>? _statsFuture;

  static const _presets = ['7d', '30d', '90d', '365d'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  void _loadStats() {
    final phone = context.read<AuthService>().user?.phoneNumber;
    if (phone == null || phone.isEmpty) return;
    setState(() {
      _statsFuture = context.read<ApiService>().fetchAdminStats(
            adminPhone: phone,
            preset: _preset,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (_statsFuture == null ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(tr(context, 'admin_stats_error')),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadStats,
                  icon: const Icon(Icons.refresh),
                  label: Text(tr(context, 'retry')),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;
        final overview =
            Map<String, dynamic>.from(stats['overview'] as Map? ?? {});
        final period = Map<String, dynamic>.from(stats['period'] as Map? ?? {});
        final series = Map<String, dynamic>.from(stats['series'] as Map? ?? {});
        final pendingShops =
            (stats['pending_shop_promos'] as List?)?.length ?? 0;
        final pendingProducts =
            (stats['pending_product_boosts'] as List?)?.length ?? 0;
        final pendingTotal = pendingShops + pendingProducts;

        return RefreshIndicator(
          onRefresh: () async => _loadStats(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr(context, 'admin_dashboard_subtitle'),
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadStats,
                    icon: const Icon(Icons.refresh),
                    tooltip: tr(context, 'retry'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((p) {
                  final selected = _preset == p;
                  return ChoiceChip(
                    label: Text(_presetLabel(context, p)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _preset = p);
                      _loadStats();
                    },
                    selectedColor: UzaColors.secondary.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              if (period['label'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${tr(context, 'admin_period')}: ${period['label']}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
              if (pendingTotal > 0) ...[
                const SizedBox(height: 20),
                _AlertCard(
                  count: pendingTotal,
                  message: tr(context, 'admin_pending_alert'),
                  onTap: widget.onOpenModeration,
                ),
              ],
              const SizedBox(height: 24),
              AdminDashboardModerationPanel(
                onOpenModeration: widget.onOpenModeration,
              ),
              const SizedBox(height: 28),
              Text(
                tr(context, 'admin_kpis'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _KpiGrid(overview: overview),
              const SizedBox(height: 28),
              Text(
                tr(context, 'admin_activity_chart'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _ActivityChart(
                visits: _seriesCounts(series['platform_visits']),
                contacts: _seriesCounts(series['contacts']),
                orders: _seriesCounts(series['orders']),
                shopViews: _seriesCounts(series['shop_views']),
                shopShares: _seriesCounts(series['shop_shares']),
              ),
              if ((stats['shop_interactions_by_type'] as List?)?.isNotEmpty ==
                  true) ...[
                const SizedBox(height: 28),
                Text(
                  tr(context, 'admin_engagement_breakdown'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _ShopInteractionsBreakdown(
                  items: stats['shop_interactions_by_type'] as List,
                ),
              ],
              const SizedBox(height: 28),
              Text(
                tr(context, 'admin_top_shops'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _TopShopsTable(
                shops: (stats['top_shops_views'] as List?) ?? [],
              ),
              const SizedBox(height: 28),
              Text(
                tr(context, 'admin_top_products'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _TopProductsTable(
                products: (stats['top_products'] as List?) ?? [],
              ),
              const SizedBox(height: 28),
              if ((stats['cities'] as List?)?.isNotEmpty == true) ...[
                Text(
                  tr(context, 'admin_cities'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _CitiesBreakdown(cities: stats['cities'] as List),
              ],
            ],
          ),
        );
      },
    );
  }

  String _presetLabel(BuildContext context, String preset) {
    switch (preset) {
      case '7d':
        return tr(context, 'admin_preset_7d');
      case '90d':
        return tr(context, 'admin_preset_90d');
      case '365d':
        return tr(context, 'admin_preset_365d');
      default:
        return tr(context, 'admin_preset_30d');
    }
  }

  List<int> _seriesCounts(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => (e is Map ? (e['count'] as num?)?.toInt() ?? 0 : 0))
        .toList();
  }
}

class _AlertCard extends StatelessWidget {
  final int count;
  final String message;
  final VoidCallback? onTap;

  const _AlertCard({
    required this.count,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: UzaColors.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.pending_actions, color: UzaColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message.replaceAll('{count}', '$count'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: UzaColors.warning),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final Map<String, dynamic> overview;

  const _KpiGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem(
        tr(context, 'admin_kpi_shops'),
        overview['shops_total'],
        overview['shops_period'],
        Icons.storefront,
        UzaColors.secondary,
      ),
      _KpiItem(
        tr(context, 'admin_kpi_products'),
        overview['products_total'],
        overview['products_period'],
        Icons.inventory_2,
        UzaColors.primary,
      ),
      _KpiItem(
        tr(context, 'admin_kpi_users'),
        overview['users_total'],
        overview['users_period'],
        Icons.people,
        Colors.indigo,
      ),
      _KpiItem(
        tr(context, 'admin_kpi_contacts'),
        overview['contacts_total'],
        overview['contacts_period'],
        Icons.chat_bubble_outline,
        Colors.green,
      ),
      _KpiItem(
        tr(context, 'admin_kpi_orders'),
        overview['orders_total'],
        overview['orders_period'],
        Icons.shopping_bag_outlined,
        Colors.deepPurple,
      ),
      _KpiItem(
        tr(context, 'admin_kpi_visits'),
        overview['platform_visits_total'],
        overview['platform_visits_period'],
        Icons.visibility_outlined,
        Colors.blue,
      ),
      _KpiItem(
        tr(context, 'admin_kpi_reports'),
        overview['reports_total'],
        overview['reports_period'],
        Icons.flag_outlined,
        Colors.red,
      ),
      _KpiItem(
        tr(context, 'admin_kpi_verified'),
        overview['shops_verified'],
        null,
        Icons.verified,
        Colors.teal,
      ),
      _KpiItem(
        tr(context, 'admin_kpi_product_views'),
        overview['product_views_total'] ?? overview['views_total'],
        null,
        Icons.remove_red_eye_outlined,
        Colors.blueGrey,
      ),
      _KpiItem(
        tr(context, 'admin_kpi_shop_views'),
        overview['shop_views_total'],
        overview['shop_views_period'],
        Icons.storefront_outlined,
        Colors.orange,
      ),
      _KpiItem(
        tr(context, 'admin_kpi_shop_shares'),
        overview['shop_shares_total'],
        overview['shop_shares_period'],
        Icons.campaign_outlined,
        Colors.deepOrange,
      ),
      _KpiItem(
        tr(context, 'admin_kpi_engagement_shares'),
        overview['engagement_shares_total'],
        overview['engagement_shares_period'],
        Icons.share_outlined,
        Colors.pink,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _KpiCard(item: items[i]),
        );
      },
    );
  }
}

class _KpiItem {
  final String label;
  final dynamic total;
  final dynamic period;
  final IconData icon;
  final Color color;

  const _KpiItem(
    this.label,
    this.total,
    this.period,
    this.icon,
    this.color,
  );
}

class _KpiCard extends StatelessWidget {
  final _KpiItem item;

  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 22),
          const Spacer(),
          Text(
            '${item.total ?? 0}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
            ),
          ),
          if (item.period != null) ...[
            const SizedBox(height: 4),
            Text(
              '+${item.period} ${tr(context, 'admin_on_period')}',
              style: TextStyle(
                fontSize: 11,
                color: item.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final List<int> visits;
  final List<int> contacts;
  final List<int> orders;
  final List<int> shopViews;
  final List<int> shopShares;

  const _ActivityChart({
    required this.visits,
    required this.contacts,
    required this.orders,
    this.shopViews = const [],
    this.shopShares = const [],
  });

  @override
  Widget build(BuildContext context) {
    final maxLen = [
      visits.length,
      contacts.length,
      orders.length,
      shopViews.length,
      shopShares.length,
    ].reduce((a, b) => a > b ? a : b);
    if (maxLen == 0) {
      return _emptyChart(context);
    }

    final displayLen = maxLen > 14 ? 14 : maxLen;
    final start = maxLen - displayLen;
    final sliceVisits = visits.length > start
        ? visits.sublist(start)
        : List.filled(displayLen, 0);
    final sliceContacts = contacts.length > start
        ? contacts.sublist(start)
        : List.filled(displayLen, 0);
    final sliceOrders = orders.length > start
        ? orders.sublist(start)
        : List.filled(displayLen, 0);
    final sliceShopViews = shopViews.length > start
        ? shopViews.sublist(start)
        : List.filled(displayLen, 0);
    final sliceShopShares = shopShares.length > start
        ? shopShares.sublist(start)
        : List.filled(displayLen, 0);

    final maxVal = [
      ...sliceVisits,
      ...sliceContacts,
      ...sliceOrders,
      ...sliceShopViews,
      ...sliceShopShares,
    ].fold<int>(0, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legend(Colors.blue, tr(context, 'admin_chart_visits')),
              _legend(Colors.green, tr(context, 'admin_chart_contacts')),
              _legend(Colors.deepPurple, tr(context, 'admin_chart_orders')),
              if (shopViews.any((v) => v > 0))
                _legend(Colors.orange, tr(context, 'admin_chart_shop_views')),
              if (shopShares.any((v) => v > 0))
                _legend(Colors.pink, tr(context, 'admin_chart_shop_shares')),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(displayLen, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _bar(sliceVisits[i], maxVal, Colors.blue),
                        _bar(sliceContacts[i], maxVal, Colors.green),
                        _bar(sliceOrders[i], maxVal, Colors.deepPurple),
                        if (shopViews.isNotEmpty)
                          _bar(sliceShopViews[i], maxVal, Colors.orange),
                        if (shopShares.isNotEmpty)
                          _bar(sliceShopShares[i], maxVal, Colors.pink),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _bar(int value, int maxVal, Color color) {
    final factor = maxVal > 0 ? (value / maxVal).clamp(0.05, 1.0) : 0.05;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: FractionallySizedBox(
          heightFactor: factor,
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyChart(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        tr(context, 'admin_no_chart_data'),
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }
}

class _ShopInteractionsBreakdown extends StatelessWidget {
  final List<dynamic> items;

  const _ShopInteractionsBreakdown({required this.items});

  String _label(String type) {
    switch (type) {
      case 'view':
        return 'Vues profil boutique';
      case 'share':
        return 'Lien boutique';
      case 'catalog_share':
        return 'Catalogue';
      case 'qr_share':
        return 'QR code';
      case 'story_share':
        return 'Story / arrivage';
      case 'whatsapp_status':
        return 'Statut WhatsApp';
      case 'facebook_status':
        return 'Statut Facebook';
      case 'tiktok_status':
        return 'Statut TikTok';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DataTableCard(
      columns: const ['Action', 'Nombre'],
      rows: items.map((raw) {
        final m = raw as Map;
        return [
          _label('${m['interaction_type'] ?? ''}'),
          '${m['count'] ?? 0}',
        ];
      }).toList(),
    );
  }
}

class _TopShopsTable extends StatelessWidget {
  final List<dynamic> shops;

  const _TopShopsTable({required this.shops});

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty) {
      return Text(tr(context, 'admin_no_data'));
    }
    return _DataTableCard(
      columns: [
        tr(context, 'shops'),
        tr(context, 'admin_col_views'),
        tr(context, 'admin_col_shop_views'),
        tr(context, 'admin_col_shares'),
      ],
      rows: shops.take(8).map((s) {
        final m = s as Map;
        return [
          '${m['name'] ?? ''}',
          '${m['product_views'] ?? m['views'] ?? 0}',
          '${m['shop_views'] ?? 0}',
          '${m['shares'] ?? 0}',
        ];
      }).toList(),
    );
  }
}

class _TopProductsTable extends StatelessWidget {
  final List<dynamic> products;

  const _TopProductsTable({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Text(tr(context, 'admin_no_data'));
    }
    return _DataTableCard(
      columns: [
        tr(context, 'products'),
        tr(context, 'shops'),
        tr(context, 'admin_col_views'),
      ],
      rows: products.take(8).map((p) {
        final m = p as Map;
        return [
          '${m['name'] ?? ''}',
          '${m['shop_name'] ?? ''}',
          '${m['views'] ?? 0}',
        ];
      }).toList(),
    );
  }
}

class _CitiesBreakdown extends StatelessWidget {
  final List<dynamic> cities;

  const _CitiesBreakdown({required this.cities});

  @override
  Widget build(BuildContext context) {
    final maxCount = cities.fold<int>(
      0,
      (m, c) {
        final count = (c is Map ? (c['shop_count'] as num?)?.toInt() : 0) ?? 0;
        return count > m ? count : m;
      },
    );

    return Column(
      children: cities.take(8).map((c) {
        final m = c as Map;
        final location = '${m['location'] ?? ''}';
        final count = (m['shop_count'] as num?)?.toInt() ?? 0;
        final factor = maxCount > 0 ? count / maxCount : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: factor,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    color: UzaColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DataTableCard extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;

  const _DataTableCard({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          columns: columns
              .map((c) => DataColumn(label: Text(c, style: const TextStyle(fontSize: 12))))
              .toList(),
          rows: rows
              .map(
                (cells) => DataRow(
                  cells: cells
                      .map((c) => DataCell(Text(c, style: const TextStyle(fontSize: 13))))
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
