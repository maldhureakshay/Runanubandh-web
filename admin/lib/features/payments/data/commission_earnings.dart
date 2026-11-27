import 'dart:math' as math;

import 'maintenance_bill.dart';
import 'maintenance_cost.dart';
import 'purchases_repository.dart';

/// Commission on amount after Google Play fees and system maintenance.
class CommissionEarningsSummary {
  CommissionEarningsSummary({
    required this.purchaseCount,
    required this.totalAmountReceivedInr,
    required this.commissionRatePercent,
    required this.lines,
    required this.maintenanceCost,
  })  : totalSystemMaintenanceCostInr = lines.fold(
          0.0,
          (sum, line) => sum + line.systemMaintenanceCostInr,
        ),
        totalAmountAfterMaintenanceInr = lines.fold(
          0.0,
          (sum, line) => sum + line.amountAfterMaintenanceInr,
        ),
        totalCommissionEarningsInr = lines.fold(
          0.0,
          (sum, line) => sum + line.commissionEarningsInr,
        );

  final int purchaseCount;
  final double totalAmountReceivedInr;
  final double commissionRatePercent;
  final List<PurchaseCommissionLine> lines;
  final MaintenanceCost maintenanceCost;
  final double totalSystemMaintenanceCostInr;
  final double totalAmountAfterMaintenanceInr;
  final double totalCommissionEarningsInr;

  MaintenanceBill? get maintenanceBill => maintenanceCost.bill;

  bool get usesFirebaseBill => maintenanceCost.usesBill;

  bool get usesFirebaseRate => maintenanceCost.usesRate;

  bool get maintenanceConfigured => maintenanceCost.isAvailable;

  double? get maintenanceRatePercent => maintenanceCost.ratePercent;

  String get maintenanceSourceLabel => maintenanceCost.sourceLabel;

  double get commissionRateFraction => commissionRatePercent / 100;

  PurchaseCommissionLine? lineForPurchaseId(String? purchaseId) {
    if (purchaseId == null) return null;
    for (final line in lines) {
      if (line.purchase['id']?.toString() == purchaseId) return line;
    }
    return null;
  }

  static CommissionEarningsSummary? compute({
    required List<Map<String, dynamic>> purchases,
    required double? commissionRatePercent,
    required MaintenanceCost maintenanceCost,
  }) {
    final rate = commissionRatePercent;
    if (rate == null || rate <= 0) return null;

    final purchaseLines = <({Map<String, dynamic> purchase, double received})>[];
    var totalReceived = 0.0;

    for (final purchase in purchases) {
      final received = PurchaseSettlement.amountReceived(purchase);
      if (received == null) continue;
      totalReceived += received;
      purchaseLines.add((purchase: purchase, received: received));
    }

    final totalMaintenance = maintenanceCost.isAvailable
        ? maintenanceCost.totalAmountInr
        : 0.0;

    final lines = <PurchaseCommissionLine>[];
    for (final entry in purchaseLines) {
      final maintenanceShare = totalReceived > 0
          ? totalMaintenance * (entry.received / totalReceived)
          : 0.0;
      lines.add(
        PurchaseCommissionLine(
          purchase: entry.purchase,
          amountReceivedInr: entry.received,
          commissionRatePercent: rate,
          systemMaintenanceCostInr: maintenanceShare,
        ),
      );
    }

    return CommissionEarningsSummary(
      purchaseCount: lines.length,
      totalAmountReceivedInr: totalReceived,
      commissionRatePercent: rate,
      lines: lines,
      maintenanceCost: maintenanceCost,
    );
  }

  static double? commissionShareForPurchase(
    Map<String, dynamic> purchase,
    CommissionEarningsSummary summary,
  ) {
    final id = purchase['id']?.toString();
    return summary.lineForPurchaseId(id)?.commissionEarningsInr;
  }
}

class PurchaseCommissionLine {
  PurchaseCommissionLine({
    required this.purchase,
    required this.amountReceivedInr,
    required this.commissionRatePercent,
    required this.systemMaintenanceCostInr,
  })  : amountAfterMaintenanceInr = math.max(
          0,
          amountReceivedInr - systemMaintenanceCostInr,
        ),
        commissionEarningsInr = math.max(
          0,
          amountReceivedInr - systemMaintenanceCostInr,
        ) *
            (commissionRatePercent / 100);

  final Map<String, dynamic> purchase;
  final double amountReceivedInr;
  final double commissionRatePercent;
  final double systemMaintenanceCostInr;
  final double amountAfterMaintenanceInr;
  final double commissionEarningsInr;

  String get userLabel {
    final name = purchase['userDisplayName']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return purchase['userId']?.toString() ?? '—';
  }

  String get productLabel =>
      purchase['productId']?.toString() ??
      purchase['product_id']?.toString() ??
      '—';
}

String formatInr(double value) {
  final whole = value == value.roundToDouble();
  return '₹${value.toStringAsFixed(whole ? 0 : 2)}';
}

String formatCommissionRate(double percent) {
  return percent == percent.roundToDouble()
      ? '${percent.round()}%'
      : '${percent.toStringAsFixed(1)}%';
}
