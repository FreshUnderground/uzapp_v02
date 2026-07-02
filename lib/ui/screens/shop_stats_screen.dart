import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import '../components/analytics_tab.dart';

/// Dedicated shop analytics screen — reachable from profile and quick actions.
class ShopStatsScreen extends StatelessWidget {
  final int shopId;

  const ShopStatsScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'statistics'))),
      body: AnalyticsTab(shopId: shopId),
    );
  }
}
