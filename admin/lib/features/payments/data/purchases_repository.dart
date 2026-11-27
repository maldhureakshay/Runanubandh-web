import 'package:cloud_firestore/cloud_firestore.dart';

import '../../users/data/users_repository.dart';

class PurchasesMonthResult {
  const PurchasesMonthResult({
    required this.purchases,
    required this.totalAmountReceivedInr,
  });

  final List<Map<String, dynamic>> purchases;
  final double totalAmountReceivedInr;
}

/// Play Store fee (30%) and net amount for a purchase row.
abstract final class PurchaseSettlement {
  static const playStoreDeductionRate = 0.30;

  /// List price used for Play deduction when the paid amount is discounted.
  static const playDeductionBaseByProductId = {
    'account_activation_399': 499.0,
    'account_activation_199': 399.0,
  };

  static double? amountValue(Map<String, dynamic> purchase) {
    final amount = purchase['amount'];
    if (amount is num) return amount.toDouble();
    return null;
  }

  static String _productId(Map<String, dynamic> purchase) =>
      purchase['productId']?.toString().trim() ??
      purchase['product_id']?.toString().trim() ??
      '';

  /// Base amount for the 30% Play deduction (list price or paid amount).
  static double playDeductionBase(Map<String, dynamic> purchase) {
    final reference = playDeductionBaseByProductId[_productId(purchase)];
    if (reference != null) return reference;
    return amountValue(purchase) ?? 0;
  }

  static double? playDeduction(Map<String, dynamic> purchase) {
    final amount = amountValue(purchase);
    if (amount == null) return null;
    return playDeductionBase(purchase) * playStoreDeductionRate;
  }

  /// List price (or paid amount) minus Play deduction — same base as deduction.
  static double? amountReceived(Map<String, dynamic> purchase) {
    if (amountValue(purchase) == null) return null;
    final base = playDeductionBase(purchase);
    return base * (1 - playStoreDeductionRate);
  }
}

class PurchasesRepository {
  PurchasesRepository(this._firestore, this._users);

  final FirebaseFirestore _firestore;
  final UsersRepository _users;

  static const int maxPerMonth = 100;

  /// Jan 2026 only: `payments` (14–27) + `purchases` (28–31). All else: full month `purchases`.
  static bool usesJanuary2026Split({required int year, required int month}) =>
      month == 1 && year == 2026;

  Future<PurchasesMonthResult> fetchForMonth({
    required int year,
    required int month,
  }) async {
    final purchases = usesJanuary2026Split(year: year, month: month)
        ? await _fetchJanuary2026()
        : await _fetchPurchasesForMonth(year: year, month: month);

    await _enrichWithUserDisplayNames(purchases);

    var totalReceived = 0.0;
    for (final p in purchases) {
      final received = PurchaseSettlement.amountReceived(p);
      if (received != null) totalReceived += received;
    }

    return PurchasesMonthResult(
      purchases: purchases,
      totalAmountReceivedInr: totalReceived,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchJanuary2026() async {
    const year = 2026;
    final fromPayments = await _fetchJanuaryPaymentsCollection(year);
    final fromPurchases = await _fetchPurchasesFromDateRange(
      start: DateTime(year, 1, 28),
      end: DateTime(year, 2, 1),
    );

    final merged = [...fromPayments, ...fromPurchases];
    merged.sort((a, b) => _purchaseTimeMillis(b).compareTo(_purchaseTimeMillis(a)));
    return merged;
  }

  /// `payments` collection: 14 Jan through 27 Jan (inclusive), by `created_at`.
  Future<List<Map<String, dynamic>>> _fetchJanuaryPaymentsCollection(int year) async {
    final start = DateTime(year, 1, 14);
    final end = DateTime(year, 1, 28);

    final snap = await _firestore
        .collection('payments')
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('created_at', isLessThan: Timestamp.fromDate(end))
        .orderBy('created_at', descending: true)
        .limit(maxPerMonth)
        .get();

    return snap.docs
        .map((d) => _normalizeRecord(d.data(), d.id))
        .where(_shouldInclude)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchPurchasesForMonth({
    required int year,
    required int month,
  }) async {
    final start = DateTime(year, month, 1);
    final end = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return _fetchPurchasesFromDateRange(start: start, end: end);
  }

  Future<List<Map<String, dynamic>>> _fetchPurchasesFromDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final snap = await _firestore
        .collection('purchases')
        .where(
          'purchaseTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('purchaseTime', isLessThan: Timestamp.fromDate(end))
        .orderBy('purchaseTime', descending: true)
        .limit(maxPerMonth)
        .get();

    return snap.docs
        .map((d) => _normalizeRecord(d.data(), d.id))
        .where(_shouldInclude)
        .toList();
  }

  static int _purchaseTimeMillis(Map<String, dynamic> row) {
    final t = row['purchaseTime'] ?? row['created_at'];
    if (t is Timestamp) return t.millisecondsSinceEpoch;
    return 0;
  }

  static Map<String, dynamic> _normalizeRecord(
    Map<String, dynamic> data,
    String id,
  ) {
    final row = Map<String, dynamic>.from(data);
    row['id'] = id;
    row['userId'] ??= data['user_id'];
    row['productId'] ??= data['product_id'];
    row['profileId'] ??= data['profile_id'];
    row['purchaseTime'] ??= data['created_at'];
    row['orderId'] ??= data['order_id'] ?? data['purchase_id'];
    if (row['purchaseState'] == null && data['status'] != null) {
      row['purchaseState'] = data['status'];
    }
    return row;
  }

  static const _excludedProductIdPrefixes = [
    'featured_profile',
    'profile_activation',
  ];

  static const _excludedUserIds = {
    'f0FUfdQPDufEM6FMOP8R8Cc89BJ3',
  };

  static bool _shouldInclude(Map<String, dynamic> purchase) {
    return _hasValidUserId(purchase) &&
        !_isExcludedUser(purchase) &&
        !_isExcludedProduct(purchase);
  }

  static bool _hasValidUserId(Map<String, dynamic> purchase) {
    final id = purchase['userId'] ?? purchase['user_id'];
    if (id == null) return false;
    final s = id.toString().trim();
    if (s.isEmpty) return false;
    if (s.toLowerCase() == 'unknown') return false;
    return true;
  }

  static bool _isExcludedUser(Map<String, dynamic> purchase) {
    final userId =
        purchase['userId']?.toString().trim() ?? purchase['user_id']?.toString().trim() ?? '';
    return _excludedUserIds.contains(userId);
  }

  static bool _isExcludedProduct(Map<String, dynamic> purchase) {
    final productId = PurchaseSettlement._productId(purchase).toLowerCase();
    return _excludedProductIdPrefixes.any(productId.startsWith);
  }

  Future<void> _enrichWithUserDisplayNames(List<Map<String, dynamic>> purchases) async {
    final userIds = purchases.map((p) => p['userId']?.toString() ?? '');
    final names = await _users.fetchDisplayNamesByIds(userIds);
    for (final p in purchases) {
      final uid = p['userId']?.toString() ?? '';
      p['userDisplayName'] = names[uid] ?? uid;
    }
  }
}
