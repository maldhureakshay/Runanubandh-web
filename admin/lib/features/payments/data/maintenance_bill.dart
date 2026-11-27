/// Monthly system maintenance bill from Firestore `bills` for a client.
class MaintenanceBill {
  const MaintenanceBill({
    required this.id,
    required this.clientId,
    required this.year,
    required this.month,
    required this.totalAmountInr,
    this.title,
    this.notes,
    this.lineItems = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clientId;
  final int year;
  final int month;
  final double totalAmountInr;
  final String? title;
  final String? notes;
  final List<MaintenanceBillLineItem> lineItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasLineItems => lineItems.isNotEmpty;

  String get displayTitle =>
      title?.trim().isNotEmpty == true ? title!.trim() : 'System maintenance bill';
}

class MaintenanceBillLineItem {
  const MaintenanceBillLineItem({
    required this.description,
    required this.amountInr,
  });

  final String description;
  final double amountInr;
}
