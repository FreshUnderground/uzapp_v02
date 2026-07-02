import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/auth_service.dart';
import '../admin_moderation_actions.dart';
class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  Future<List<Map<String, dynamic>>>? _reportsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final phone = context.read<AuthService>().user?.phoneNumber;
    if (phone == null) return;
    setState(() {
      _reportsFuture = context.read<ApiService>().fetchAdminReports(
            adminPhone: phone,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data ?? [];
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_outlined, size: 56, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(tr(context, 'admin_no_reports')),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: Text(tr(context, 'retry')),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${report['reason'] ?? ''}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate('${report['created_at'] ?? ''}'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${report['product_name'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tr(context, 'shops')}: ${report['shop_name'] ?? ''}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                      if (report['details'] != null &&
                          '${report['details']}'.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${report['details']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${report['reporter_phone'] ?? tr(context, 'admin_anonymous')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () async {
                              final serverProductId = int.tryParse(
                                '${report['product_id'] ?? ''}',
                              );
                              if (serverProductId == null) return;
                              final ok =
                                  await AdminModerationActions.deleteProduct(
                                context,
                                serverProductId: serverProductId,
                                productName:
                                    '${report['product_name'] ?? ''}',
                              );
                              if (ok && context.mounted) _load();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: Text(
                              tr(context, 'admin_delete_product'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(String raw) {
    if (raw.length >= 16) return raw.substring(0, 16).replaceFirst('T', ' ');
    return raw;
  }
}
