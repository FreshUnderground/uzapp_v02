import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/res/uza_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/auth_service.dart';

class AdminActivityTab extends StatefulWidget {
  const AdminActivityTab({super.key});

  @override
  State<AdminActivityTab> createState() => _AdminActivityTabState();
}

class _AdminActivityTabState extends State<AdminActivityTab> {
  Future<Map<String, dynamic>?>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final phone = context.read<AuthService>().user?.phoneNumber;
    if (phone == null) return;
    setState(() {
      _statsFuture = context.read<ApiService>().fetchAdminStats(
            adminPhone: phone,
            preset: '7d',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == null) {
          return Center(
            child: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(tr(context, 'retry')),
            ),
          );
        }

        final stats = snapshot.data!;
        final orders = (stats['recent_orders'] as List?) ?? [];
        final contacts = (stats['recent_contacts'] as List?) ?? [];
        final ordersByStatus = (stats['orders_by_status'] as List?) ?? [];
        final overview =
            Map<String, dynamic>.from(stats['overview'] as Map? ?? {});

        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                tr(context, 'admin_activity_summary'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryChip(
                    label: tr(context, 'admin_kpi_orders'),
                    value: '${overview['orders_period'] ?? 0}',
                    icon: Icons.shopping_bag,
                    color: Colors.deepPurple,
                  ),
                  _SummaryChip(
                    label: tr(context, 'admin_kpi_contacts'),
                    value: '${overview['contacts_period'] ?? 0}',
                    icon: Icons.chat,
                    color: Colors.green,
                  ),
                  _SummaryChip(
                    label: tr(context, 'admin_orders_pending'),
                    value: '${overview['orders_pending'] ?? 0}',
                    icon: Icons.hourglass_empty,
                    color: UzaColors.warning,
                  ),
                ],
              ),
              if (ordersByStatus.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  tr(context, 'admin_orders_by_status'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...ordersByStatus.map((row) {
                  final m = row as Map;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.circle, size: 10),
                    title: Text('${m['status'] ?? ''}'),
                    trailing: Text(
                      '${m['count'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),
              Text(
                tr(context, 'admin_recent_orders'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (orders.isEmpty)
                Text(tr(context, 'admin_no_data'))
              else
                ...orders.map((o) => _OrderTile(order: o as Map)),
              const SizedBox(height: 24),
              Text(
                tr(context, 'admin_recent_contacts'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (contacts.isEmpty)
                Text(tr(context, 'admin_no_data'))
              else
                ...contacts.map((c) => _ContactTile(contact: c as Map)),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withValues(alpha: 0.15),
          child: const Icon(Icons.receipt_long, color: Colors.deepPurple),
        ),
        title: Text('${order['shop_name'] ?? ''}'),
        subtitle: Text(
          '${order['buyer_phone'] ?? ''} · ${_formatDate('${order['created_at'] ?? ''}')}',
        ),
        trailing: Chip(
          label: Text(
            '${order['status'] ?? ''}',
            style: const TextStyle(fontSize: 11),
          ),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.length >= 16) return raw.substring(0, 16).replaceFirst('T', ' ');
    return raw;
  }
}

class _ContactTile extends StatelessWidget {
  final Map contact;

  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          child: const Icon(Icons.chat_bubble_outline, color: Colors.green),
        ),
        title: Text('${contact['shop_name'] ?? ''}'),
        subtitle: Text(
          '${contact['product_name'] ?? tr(context, 'admin_direct_contact')} · ${contact['user_phone'] ?? ''}',
        ),
        trailing: Text(
          '${contact['contact_type'] ?? ''}',
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}
