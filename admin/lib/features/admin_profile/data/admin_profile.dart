/// Signed-in admin profile from `admins/{uid}` with linked `clients/{client_id}`.
class AdminProfile {
  const AdminProfile({
    required this.uid,
    this.firstName,
    this.lastName,
    this.clientId,
    this.clientName,
    this.commissionRate,
  });

  final String uid;
  final String? firstName;
  final String? lastName;
  final String? clientId;
  final String? clientName;
  final double? commissionRate;

  bool get hasFirestoreDoc =>
      (firstName?.trim().isNotEmpty ?? false) ||
      (lastName?.trim().isNotEmpty ?? false) ||
      (clientId?.trim().isNotEmpty ?? false);

  bool get hasClient =>
      clientId != null && clientId!.trim().isNotEmpty;

  String get displayName {
    final parts = [
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(' ');
    return 'Admin';
  }

  String? get commissionLabel {
    final rate = commissionRate;
    if (rate == null) return null;
    final formatted =
        rate == rate.roundToDouble() ? rate.round().toString() : rate.toString();
    return '$formatted%';
  }
}
