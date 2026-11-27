import 'package:cloud_firestore/cloud_firestore.dart';

import 'picker_group.dart';

/// Firestore reads for admin profile form options.
class ProfileFormOptions {
  ProfileFormOptions(this._firestore);

  final FirebaseFirestore _firestore;

  /// `app_config/subcaste_options` → `options` array.
  Future<List<String>> fetchBranchOptions() async {
    final doc =
        await _firestore.collection('app_config').doc('subcaste_options').get();
    if (!doc.exists || doc.data() == null) return const [];
    final raw = doc.data()!['options'] as List<dynamic>? ?? const [];
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  /// `picker_options/{docKey}` → `groups` array (same shape as mobile app).
  Future<List<PickerGroup>> fetchPickerGroups(String docKey) async {
    final doc = await _firestore.collection('picker_options').doc(docKey).get();
    if (!doc.exists || doc.data() == null) return const [];

    final rawGroups = doc.data()!['groups'] as List<dynamic>? ?? const [];
    return rawGroups.map((g) {
      final map = g as Map<String, dynamic>;
      return PickerGroup(
        label: map['label'] as String? ?? '',
        items: (map['items'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList(),
      );
    }).toList();
  }

  /// Ensures [current] appears in the list when editing legacy/custom values.
  static List<String> withCurrentValue(String? current, List<String> options) {
    final c = current?.trim();
    if (c == null || c.isEmpty) return options;
    if (options.contains(c)) return options;
    return [c, ...options];
  }
}
