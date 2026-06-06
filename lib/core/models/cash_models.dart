class CashSession {
  final int id;
  final int shopId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingBalance;
  final double? closingBalance;
  final double? expectedBalance;
  final String? openedBy;
  final String? closedBy;
  final String? notes;
  final String status;

  const CashSession({
    required this.id,
    required this.shopId,
    required this.openedAt,
    this.closedAt,
    required this.openingBalance,
    this.closingBalance,
    this.expectedBalance,
    this.openedBy,
    this.closedBy,
    this.notes,
    required this.status,
  });

  factory CashSession.fromJson(Map<String, dynamic> json) {
    return CashSession(
      id: json['id'] as int,
      shopId: json['shop_id'] as int,
      openedAt: DateTime.parse(json['opened_at'] as String),
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      openingBalance: _toDouble(json['opening_balance']),
      closingBalance: json['closing_balance'] != null
          ? _toDouble(json['closing_balance'])
          : null,
      expectedBalance: json['expected_balance'] != null
          ? _toDouble(json['expected_balance'])
          : null,
      openedBy: json['opened_by'] as String?,
      closedBy: json['closed_by'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'open',
    );
  }

  bool get isOpen => status == 'open';
}

class CashTransaction {
  final int id;
  final int sessionId;
  final int shopId;
  final String type;
  final double amount;
  final String? description;
  final String paymentMethod;
  final String? createdBy;
  final DateTime createdAt;

  const CashTransaction({
    required this.id,
    required this.sessionId,
    required this.shopId,
    required this.type,
    required this.amount,
    this.description,
    required this.paymentMethod,
    this.createdBy,
    required this.createdAt,
  });

  factory CashTransaction.fromJson(Map<String, dynamic> json) {
    return CashTransaction(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      shopId: json['shop_id'] as int,
      type: json['type'] as String,
      amount: _toDouble(json['amount']),
      description: json['description'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isIncome => type == 'sale' || type == 'deposit';
}

class CashSummary {
  final double sales;
  final double expenses;
  final double withdrawals;
  final double deposits;
  final double currentBalance;

  const CashSummary({
    this.sales = 0,
    this.expenses = 0,
    this.withdrawals = 0,
    this.deposits = 0,
    this.currentBalance = 0,
  });

  factory CashSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CashSummary();
    return CashSummary(
      sales: _toDouble(json['sales']),
      expenses: _toDouble(json['expenses']),
      withdrawals: _toDouble(json['withdrawals']),
      deposits: _toDouble(json['deposits']),
      currentBalance: _toDouble(json['current_balance']),
    );
  }
}

class CashDashboard {
  final CashSession? session;
  final List<CashTransaction> transactions;
  final CashSummary summary;

  const CashDashboard({
    this.session,
    this.transactions = const [],
    this.summary = const CashSummary(),
  });

  factory CashDashboard.fromJson(Map<String, dynamic> json) {
    return CashDashboard(
      session: json['session'] != null
          ? CashSession.fromJson(json['session'] as Map<String, dynamic>)
          : null,
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((e) => CashTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: CashSummary.fromJson(
        json['summary'] as Map<String, dynamic>?,
      ),
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
