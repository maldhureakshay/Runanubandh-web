import 'package:cloud_firestore/cloud_firestore.dart';

import 'picker_group.dart';
import 'profile_form_options.dart';

/// In-memory cache for branch / picker options (one Firestore read per app session).
class ProfileFormOptionsCache {
  ProfileFormOptionsCache(FirebaseFirestore firestore)
      : _source = ProfileFormOptions(firestore);

  final ProfileFormOptions _source;

  List<String>? _branchOptions;
  List<PickerGroup>? _educationGroups;
  List<PickerGroup>? _occupationGroups;
  Future<void>? _loadFuture;

  bool get isLoaded =>
      _branchOptions != null &&
      _educationGroups != null &&
      _occupationGroups != null;

  /// Loads all config documents once; subsequent calls are no-ops.
  Future<void> ensureLoaded() async {
    if (isLoaded) return;
    _loadFuture ??= _loadAll();
    await _loadFuture;
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      _source.fetchBranchOptions(),
      _source.fetchPickerGroups('education'),
      _source.fetchPickerGroups('occupation'),
    ]);
    _branchOptions = results[0] as List<String>;
    _educationGroups = results[1] as List<PickerGroup>;
    _occupationGroups = results[2] as List<PickerGroup>;
  }

  List<String> get branchOptions =>
      List<String>.from(_branchOptions ?? const []);

  List<PickerGroup> get educationGroups =>
      List<PickerGroup>.from(_educationGroups ?? const []);

  List<PickerGroup> get occupationGroups =>
      List<PickerGroup>.from(_occupationGroups ?? const []);

  List<PickerGroup> groupsForKey(String pickerKey) {
    switch (pickerKey) {
      case 'education':
        return educationGroups;
      case 'occupation':
        return occupationGroups;
      default:
        return const [];
    }
  }

  /// Whether [value] appears in any item of [groups].
  static bool valueInGroups(String? value, List<PickerGroup> groups) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return false;
    for (final g in groups) {
      if (g.items.contains(v)) return true;
    }
    return false;
  }

  static void clearCacheForTesting() {
    // Reserved for tests; instance fields cleared by creating a new cache.
  }
}
