import 'package:cloud_firestore/cloud_firestore.dart';

import 'maintenance_bill.dart';
import 'maintenance_bill_repository.dart';
import 'maintenance_cost.dart';

/// Resolves maintenance cost for a month entirely from Firestore.
///
/// Order:
/// 1. Monthly bill (`bills` collection or `clients/{id}/bills/...`)
/// 2. Maintenance rate % on `clients/{client_id}` (e.g. `system_maintenance_rate`)
/// 3. Maintenance rate % on `app_config/system_maintenance` (or `app_config/earnings`)
class MaintenanceCostRepository {
  MaintenanceCostRepository(this._firestore, this._bills);

  final FirebaseFirestore _firestore;
  final MaintenanceBillRepository _bills;

  Future<MaintenanceCost> resolve({
    required String? clientId,
    required int year,
    required int month,
    required double totalAmountReceivedInr,
  }) async {
    if (clientId != null && clientId.trim().isNotEmpty) {
      final bill = await _bills.fetchForClientMonth(
        clientId: clientId,
        year: year,
        month: month,
      );
      if (bill != null) {
        return MaintenanceCost(
          source: MaintenanceCostSource.monthlyBill,
          totalAmountInr: bill.totalAmountInr,
          bill: bill,
        );
      }

      final clientRate = await _rateFromClient(clientId);
      if (clientRate != null) {
        return _costFromRate(
          ratePercent: clientRate.rate,
          configPath: clientRate.path,
          totalAmountReceivedInr: totalAmountReceivedInr,
        );
      }
    }

    final appRate = await _rateFromAppConfig();
    if (appRate != null) {
      return _costFromRate(
        ratePercent: appRate.rate,
        configPath: appRate.path,
        totalAmountReceivedInr: totalAmountReceivedInr,
      );
    }

    return const MaintenanceCost(
      source: MaintenanceCostSource.unavailable,
      totalAmountInr: 0,
    );
  }

  MaintenanceCost _costFromRate({
    required double ratePercent,
    required String configPath,
    required double totalAmountReceivedInr,
  }) {
    final amount = totalAmountReceivedInr * (ratePercent / 100);
    return MaintenanceCost(
      source: MaintenanceCostSource.firebaseRate,
      totalAmountInr: amount,
      ratePercent: ratePercent,
      rateConfigPath: configPath,
    );
  }

  Future<({double rate, String path})?> _rateFromClient(String clientId) async {
    final snap =
        await _firestore.collection('clients').doc(clientId.trim()).get();
    if (!snap.exists) return null;

    final rate = _percentField(snap.data() ?? {}, [
      'system_maintenance_rate',
      'system_maintenance_rate_percent',
      'maintenance_rate',
      'maintenance_rate_percent',
      'maintenance_cost_rate',
    ]);
    if (rate == null) return null;
    return (rate: rate, path: 'clients/${snap.id}');
  }

  Future<({double rate, String path})?> _rateFromAppConfig() async {
    for (final docId in ['system_maintenance', 'earnings', 'maintenance']) {
      final snap =
          await _firestore.collection('app_config').doc(docId).get();
      if (!snap.exists) continue;

      final rate = _percentField(snap.data() ?? {}, [
        'system_maintenance_rate',
        'system_maintenance_rate_percent',
        'maintenance_rate',
        'maintenance_rate_percent',
        'maintenance_cost_rate',
        'rate',
        'percent',
      ]);
      if (rate != null) {
        return (rate: rate, path: 'app_config/$docId');
      }
    }
    return null;
  }
}

double? _percentField(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is num && value > 0) return value.toDouble();
  }
  return null;
}
