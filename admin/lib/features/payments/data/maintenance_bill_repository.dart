import 'package:cloud_firestore/cloud_firestore.dart';

import 'maintenance_bill.dart';

/// Reads monthly maintenance bills from Firestore `bills`.
///
/// Supported document lookup (tried in order):
/// 1. Document ID `{client_id}_{year}_{month}` — month without leading zero (e.g. `abc_2026_5`)
/// 2. Document ID `{client_id}_{year}_{MM}` — month with leading zero (e.g. `abc_2026_05`)
/// 3. Query: `client_id` + `year` + `month`
///
/// Expected fields (any one amount field works):
/// `amount`, `total_amount`, `total`, `maintenance_cost`, `maintenance_amount`
///
/// Optional: `title`, `notes`, `description`, `items` / `line_items` (array of maps
/// with `description` + `amount`).
class MaintenanceBillRepository {
  MaintenanceBillRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<MaintenanceBill?> fetchForClientMonth({
    required String clientId,
    required int year,
    required int month,
  }) async {
    final trimmedClientId = clientId.trim();
    if (trimmedClientId.isEmpty) return null;

    final docIds = [
      '${trimmedClientId}_${year}_$month',
      '${trimmedClientId}_${year}_${month.toString().padLeft(2, '0')}',
    ];

    for (final id in docIds) {
      final snap = await _firestore.collection('bills').doc(id).get();
      if (snap.exists) {
        final bill = _fromFirestore(snap.id, snap.data() ?? {});
        if (bill != null) return bill;
      }
    }

    for (final subId in docIds) {
      final snap = await _firestore
          .collection('clients')
          .doc(trimmedClientId)
          .collection('bills')
          .doc(subId)
          .get();
      if (snap.exists) {
        final bill = _fromFirestore(snap.id, snap.data() ?? {});
        if (bill != null) return bill;
      }
    }

    final globalIds = ['${year}_$month', '${year}_${month.toString().padLeft(2, '0')}'];
    for (final id in globalIds) {
      final snap = await _firestore.collection('bills').doc(id).get();
      if (!snap.exists) continue;
      final data = snap.data() ?? {};
      final docClientId = _stringField(data, 'client_id');
      if (docClientId != null &&
          docClientId.isNotEmpty &&
          docClientId != trimmedClientId) {
        continue;
      }
      final bill = _fromFirestore(snap.id, data);
      if (bill != null) return bill;
    }

    final querySnap = await _firestore
        .collection('bills')
        .where('client_id', isEqualTo: trimmedClientId)
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .limit(1)
        .get();

    if (querySnap.docs.isEmpty) return null;
    final doc = querySnap.docs.first;
    return _fromFirestore(doc.id, doc.data());
  }

  MaintenanceBill? _fromFirestore(String id, Map<String, dynamic> data) {
    final amount = _amountField(data);
    if (amount == null || amount <= 0) return null;

    final clientId = _stringField(data, 'client_id') ?? '';
    final year = _intField(data, 'year');
    final month = _intField(data, 'month');

    return MaintenanceBill(
      id: id,
      clientId: clientId,
      year: year ?? 0,
      month: month ?? 0,
      totalAmountInr: amount,
      title: _stringField(data, 'title') ?? _stringField(data, 'name'),
      notes: _stringField(data, 'notes') ?? _stringField(data, 'description'),
      lineItems: _parseLineItems(data),
      createdAt: _timestampField(data, 'created_at') ?? _timestampField(data, 'createdAt'),
      updatedAt: _timestampField(data, 'updated_at') ?? _timestampField(data, 'updatedAt'),
    );
  }

  List<MaintenanceBillLineItem> _parseLineItems(Map<String, dynamic> data) {
    final raw = data['items'] ?? data['line_items'] ?? data['lineItems'];
    if (raw is! List) return const [];

    final items = <MaintenanceBillLineItem>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final description = _stringField(map, 'description') ??
          _stringField(map, 'name') ??
          _stringField(map, 'title') ??
          'Item';
      final amount = _amountField(map);
      if (amount == null) continue;
      items.add(
        MaintenanceBillLineItem(description: description, amountInr: amount),
      );
    }
    return items;
  }
}

String? _stringField(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _intField(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _amountField(Map<String, dynamic> data) {
  for (final key in [
    'amount',
    'total_amount',
    'total',
    'maintenance_cost',
    'maintenance_amount',
  ]) {
    final value = data[key];
    if (value is num && value > 0) return value.toDouble();
  }
  return null;
}

DateTime? _timestampField(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is Timestamp) return value.toDate();
  return null;
}
