import 'package:cloud_firestore/cloud_firestore.dart';

class UsersPageResult {
  const UsersPageResult({
    required this.users,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<Map<String, dynamic>> users;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

class UsersRepository {
  UsersRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const int defaultPageSize = 10;

  /// Latest users first (`createdAt` descending). Same query shape as mobile
  /// [AdminService.getUsersPage].
  Future<UsersPageResult> fetchPage({
    int pageSize = defaultPageSize,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.get();
    final users = snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return data;
    }).toList();

    final last = snap.docs.isEmpty ? null : snap.docs.last;
    final hasMore = snap.docs.length >= pageSize;

    return UsersPageResult(users: users, lastDocument: last, hasMore: hasMore);
  }

  /// Strips spaces, dashes, and parentheses for phone lookups.
  static String normalizePhoneInput(String raw) =>
      raw.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

  /// Finds users whose [phoneNumber] matches the query: exact match, optional
  /// `+91` prefix for 10-digit Indian numbers, then a string-prefix range on
  /// `phoneNumber` (needs at least 3 characters).
  Future<UsersPageResult> searchUsersByPhone(
    String rawQuery, {
    int limit = 50,
  }) async {
    final q = normalizePhoneInput(rawQuery);
    if (q.isEmpty) {
      return const UsersPageResult(users: [], lastDocument: null, hasMore: false);
    }

    final seen = <String>{};
    final out = <Map<String, dynamic>>[];

    void collect(QuerySnapshot<Map<String, dynamic>> snap) {
      for (final d in snap.docs) {
        if (seen.add(d.id)) {
          final data = Map<String, dynamic>.from(d.data());
          data['id'] = d.id;
          out.add(data);
        }
      }
    }

    var snap = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: q)
        .limit(limit)
        .get();
    collect(snap);

    if (out.isEmpty && RegExp(r'^\d{10}$').hasMatch(q)) {
      snap = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: '+91$q')
          .limit(limit)
          .get();
      collect(snap);
    }

    if (out.isEmpty && q.length >= 3) {
      final upper = '$q\u{f8ff}';
      snap = await _firestore
          .collection('users')
          .where('phoneNumber', isGreaterThanOrEqualTo: q)
          .where('phoneNumber', isLessThan: upper)
          .limit(limit)
          .get();
      collect(snap);
    }

    return UsersPageResult(users: out, lastDocument: null, hasMore: false);
  }

  /// Updates only name fields and timestamps. Does **not** modify `status`.
  Future<void> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
  }) async {
    final f = firstName.trim();
    final l = lastName.trim();
    final display = '$f $l'.trim();

    final update = <String, dynamic>{
      'first_name': f,
      'last_name': l,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (display.isNotEmpty) {
      update['displayName'] = display;
    }

    await _firestore.collection('users').doc(userId).update(update);
  }

  /// Removes the Firestore `users/{userId}` document only.
  /// Firebase Auth user (if any) is **not** deleted from the client.
  Future<void> deleteUserDocument(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  /// Resolves `users/{userId}` → display label (`displayName`, else first + last name).
  Future<Map<String, String>> fetchDisplayNamesByIds(Iterable<String> userIds) async {
    final unique = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (unique.isEmpty) return {};

    final result = <String, String>{};
    final list = unique.toList();

    for (var i = 0; i < list.length; i += 30) {
      final end = i + 30 < list.length ? i + 30 : list.length;
      final chunk = list.sublist(i, end);
      final snap = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final label = resolveDisplayName(doc.data());
        if (label != null) result[doc.id] = label;
      }
    }

    return result;
  }

  static String? resolveDisplayName(Map<String, dynamic> data) {
    final display = data['displayName']?.toString().trim();
    if (display != null && display.isNotEmpty) return display;

    final first = data['first_name']?.toString().trim() ?? '';
    final last = data['last_name']?.toString().trim() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;

    return null;
  }
}
