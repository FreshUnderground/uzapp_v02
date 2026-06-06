import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/models/cash_models.dart';
import '../../core/services/api_service.dart';

class CashRepository {
  final ApiService _api;

  CashRepository(this._api);

  Map<String, String> get _headers => {
    'X-API-Key': ApiService.apiKey,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String get _base => '${_api.baseUrl}/caisse.php';

  Future<CashDashboard> fetchDashboard(int shopId) async {
    final uri = Uri.parse('$_base?api_key=${ApiService.apiKey}&shop_id=$shopId');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Erreur chargement caisse (${response.statusCode})');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['error'] ?? 'Erreur caisse');
    }
    return CashDashboard.fromJson(body);
  }

  Future<List<CashSession>> fetchHistory(int shopId) async {
    final uri = Uri.parse(
      '$_base?api_key=${ApiService.apiKey}&shop_id=$shopId&history=1',
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) return [];
    return (body['sessions'] as List<dynamic>? ?? [])
        .map((e) => CashSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int?> openSession({
    required int shopId,
    required double openingBalance,
    String? openedBy,
    String? notes,
  }) async {
    return _post({
      'action': 'open_session',
      'shop_id': shopId,
      'opening_balance': openingBalance,
      'opened_by': openedBy,
      'notes': notes,
    });
  }

  Future<bool> closeSession({
    required int shopId,
    required int sessionId,
    required double closingBalance,
    required double expectedBalance,
    String? closedBy,
    String? notes,
  }) async {
    final id = await _post({
      'action': 'close_session',
      'shop_id': shopId,
      'session_id': sessionId,
      'closing_balance': closingBalance,
      'expected_balance': expectedBalance,
      'closed_by': closedBy,
      'notes': notes,
    });
    return id != null;
  }

  Future<int?> addTransaction({
    required int shopId,
    required int sessionId,
    required String type,
    required double amount,
    String? description,
    String paymentMethod = 'cash',
    String? createdBy,
  }) async {
    return _post({
      'action': 'add_transaction',
      'shop_id': shopId,
      'session_id': sessionId,
      'type': type,
      'amount': amount,
      'description': description,
      'payment_method': paymentMethod,
      'created_by': createdBy,
    });
  }

  Future<int?> _post(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$_base?api_key=${ApiService.apiKey}');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return body['id'] as int?;
        }
        throw Exception(body['error'] ?? 'Erreur serveur');
      }
      final body = jsonDecode(response.body);
      throw Exception(
        body is Map ? (body['error'] ?? 'HTTP ${response.statusCode}') : 'HTTP ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('CashRepository error: $e');
      rethrow;
    }
  }
}
