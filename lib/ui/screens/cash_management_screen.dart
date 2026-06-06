import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/cash_models.dart';
import '../../core/res/uza_colors.dart';
import '../../data/local/uza_database.dart';
import '../../data/repositories/cash_repository.dart';
import '../../data/repositories/shop_repository.dart';
import '../../core/services/auth_service.dart';
import '../components/modern_card.dart';

class CashManagementScreen extends StatefulWidget {
  const CashManagementScreen({super.key});

  @override
  State<CashManagementScreen> createState() => _CashManagementScreenState();
}

class _CashManagementScreenState extends State<CashManagementScreen> {
  Shop? _selectedShop;
  CashDashboard? _dashboard;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadShops());
  }

  Future<void> _loadShops() async {
    final shopRepo = context.read<ShopRepository>();
    final shops = await shopRepo.watchAllShops().first;
    if (!mounted) return;
    setState(() {
      _selectedShop = shops.isNotEmpty ? shops.first : null;
    });
    if (_selectedShop != null) await _refresh();
  }

  int? _serverShopId(Shop? shop) {
    if (shop?.remoteId == null) return null;
    return int.tryParse(shop!.remoteId!);
  }

  Future<void> _refresh() async {
    final shop = _selectedShop;
    final shopId = _serverShopId(shop);
    if (shopId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dash = await context.read<CashRepository>().fetchDashboard(shopId);
      if (mounted) setState(() => _dashboard = dash);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSession() async {
    final shop = _selectedShop;
    final shopId = _serverShopId(shop);
    if (shopId == null) return;
    final controller = TextEditingController(text: '0');
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ouvrir la caisse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fonds de caisse (CDF)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optionnel)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ouvrir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final user = context.read<AuthService>().user?.phoneNumber;
    try {
      await context.read<CashRepository>().openSession(
        shopId: shopId,
        openingBalance: double.tryParse(controller.text) ?? 0,
        openedBy: user,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caisse ouverte')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _closeSession() async {
    final session = _dashboard?.session;
    final shop = _selectedShop;
    final shopId = _serverShopId(shop);
    if (session == null || shopId == null) return;
    final expected = _dashboard!.summary.currentBalance;
    final controller = TextEditingController(text: expected.toStringAsFixed(0));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fermer la caisse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Solde attendu: ${expected.toStringAsFixed(0)} CDF'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Solde compté (CDF)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Fermer')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final counted = double.tryParse(controller.text) ?? expected;
    final user = context.read<AuthService>().user?.phoneNumber;
    try {
      await context.read<CashRepository>().closeSession(
        shopId: shopId,
        sessionId: session.id,
        closingBalance: counted,
        expectedBalance: expected,
        closedBy: user,
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caisse fermée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _addTransaction(String type) async {
    final session = _dashboard?.session;
    final shop = _selectedShop;
    final shopId = _serverShopId(shop);
    if (session == null || shopId == null) return;
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String paymentMethod = 'cash';
    final labels = {
      'sale': 'Vente',
      'expense': 'Dépense',
      'withdrawal': 'Retrait',
      'deposit': 'Dépôt',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(labels[type] ?? type),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant (CDF)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              if (type == 'sale') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(labelText: 'Paiement'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'mobile_money', child: Text('Mobile Money')),
                    DropdownMenuItem(value: 'card', child: Text('Carte')),
                  ],
                  onChanged: (v) => setDialogState(() => paymentMethod = v ?? 'cash'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) return;
    final user = context.read<AuthService>().user?.phoneNumber;
    try {
      await context.read<CashRepository>().addTransaction(
        shopId: shopId,
        sessionId: session.id,
        type: type,
        amount: amount,
        description: descController.text.isEmpty ? null : descController.text,
        paymentMethod: paymentMethod,
        createdBy: user,
      );
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Caisse'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: _selectedShop == null
          ? const Center(child: Text('Aucune boutique disponible'))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildShopSelector(),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_error != null)
                    ModernCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    )
                  else ...[
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildSessionActions(),
                    const SizedBox(height: 16),
                    _buildTransactionsList(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildShopSelector() {
    return StreamBuilder<List<Shop>>(
      stream: context.read<ShopRepository>().watchAllShops(),
      builder: (context, snapshot) {
        final shops = snapshot.data ?? [];
        if (shops.isEmpty) return const SizedBox.shrink();
        return DropdownButtonFormField<Shop>(
          value: _selectedShop,
          decoration: const InputDecoration(labelText: 'Boutique'),
          items: shops.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
          onChanged: (s) {
            setState(() => _selectedShop = s);
            _refresh();
          },
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    final s = _dashboard?.summary ?? const CashSummary();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryCard('Solde', s.currentBalance, UzaColors.secondary, Icons.account_balance_wallet),
        _summaryCard('Ventes', s.sales, Colors.green, Icons.trending_up),
        _summaryCard('Dépenses', s.expenses, Colors.orange, Icons.receipt_long),
        _summaryCard('Retraits', s.withdrawals, Colors.red, Icons.money_off),
      ],
    );
  }

  Widget _summaryCard(String label, double value, Color color, IconData icon) {
    return SizedBox(
      width: 160,
      child: ModernCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)} CDF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionActions() {
    final session = _dashboard?.session;
    if (session == null) {
      return FilledButton.icon(
        onPressed: _openSession,
        icon: const Icon(Icons.lock_open),
        label: const Text('Ouvrir la caisse'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModernCard(
          child: ListTile(
            leading: const Icon(Icons.access_time, color: UzaColors.primary),
            title: const Text('Session ouverte'),
            subtitle: Text('Depuis ${session.openedAt.toLocal()}'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _actionChip('Vente', Icons.add_shopping_cart, 'sale', Colors.green),
            _actionChip('Dépense', Icons.remove_circle_outline, 'expense', Colors.orange),
            _actionChip('Retrait', Icons.money_off, 'withdrawal', Colors.red),
            _actionChip('Dépôt', Icons.savings, 'deposit', UzaColors.secondary),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _closeSession,
          icon: const Icon(Icons.lock),
          label: const Text('Fermer la caisse'),
        ),
      ],
    );
  }

  Widget _actionChip(String label, IconData icon, String type, Color color) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: () => _addTransaction(type),
    );
  }

  Widget _buildTransactionsList() {
    final txs = _dashboard?.transactions ?? [];
    if (txs.isEmpty) {
      return const ModernCard(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Aucune transaction')),
        ),
      );
    }
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...txs.map(_transactionTile),
        ],
      ),
    );
  }

  Widget _transactionTile(CashTransaction tx) {
    final labels = {
      'sale': 'Vente',
      'expense': 'Dépense',
      'withdrawal': 'Retrait',
      'deposit': 'Dépôt',
    };
    final color = tx.isIncome ? Colors.green : Colors.red;
    final sign = tx.isIncome ? '+' : '-';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
      ),
      title: Text(labels[tx.type] ?? tx.type),
      subtitle: Text(tx.description ?? tx.paymentMethod),
      trailing: Text(
        '$sign${tx.amount.toStringAsFixed(0)}',
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
