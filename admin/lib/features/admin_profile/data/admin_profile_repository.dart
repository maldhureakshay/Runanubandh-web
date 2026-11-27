import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_profile.dart';

class AdminProfileRepository {
  AdminProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Loads `admins/{uid}` and resolves the linked client for [commission_rate].
  Future<AdminProfile> fetchForUser(String uid) async {
    final adminSnap = await _firestore.collection('admins').doc(uid).get();
    if (!adminSnap.exists) {
      return AdminProfile(uid: uid);
    }

    final data = adminSnap.data() ?? {};
    final firstName = _stringField(data, 'first_name');
    final lastName = _stringField(data, 'last_name');
    final clientId = _stringField(data, 'client_id');

    if (clientId == null || clientId.isEmpty) {
      return AdminProfile(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
      );
    }

    final clientSnap =
        await _firestore.collection('clients').doc(clientId).get();
    if (!clientSnap.exists) {
      return AdminProfile(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        clientId: clientId,
      );
    }

    final clientData = clientSnap.data() ?? {};
    return AdminProfile(
      uid: uid,
      firstName: firstName,
      lastName: lastName,
      clientId: clientId,
      clientName: _stringField(clientData, 'name'),
      commissionRate: _numField(clientData, 'commission_rate'),
    );
  }
}

String? _stringField(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double? _numField(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is num) return value.toDouble();
  return null;
}
