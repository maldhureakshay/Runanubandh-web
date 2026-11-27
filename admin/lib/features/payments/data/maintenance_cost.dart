import 'maintenance_bill.dart';

/// How system maintenance cost was resolved from Firestore.
enum MaintenanceCostSource {
  monthlyBill,
  firebaseRate,
  unavailable,
}

/// Maintenance cost for a month — always loaded from Firebase (bill or rate).
class MaintenanceCost {
  const MaintenanceCost({
    required this.source,
    required this.totalAmountInr,
    this.bill,
    this.ratePercent,
    this.rateConfigPath,
  });

  final MaintenanceCostSource source;
  final double totalAmountInr;
  final MaintenanceBill? bill;
  final double? ratePercent;
  final String? rateConfigPath;

  bool get isAvailable => source != MaintenanceCostSource.unavailable;

  bool get usesBill => source == MaintenanceCostSource.monthlyBill;

  bool get usesRate => source == MaintenanceCostSource.firebaseRate;

  String get sourceLabel {
    switch (source) {
      case MaintenanceCostSource.monthlyBill:
        return 'Monthly bill';
      case MaintenanceCostSource.firebaseRate:
        return 'Rate from Firestore';
      case MaintenanceCostSource.unavailable:
        return 'Not configured';
    }
  }
}
