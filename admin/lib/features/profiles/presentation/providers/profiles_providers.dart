import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_form_options_cache.dart';
import '../../data/profiles_repository.dart';

final profilesRepositoryProvider = Provider<ProfilesRepository>((ref) {
  return ProfilesRepository(
    FirebaseFirestore.instance,
    ref.watch(profileFormOptionsCacheProvider),
  );
});

/// Session cache for branch + picker options (loaded once per app run).
final profileFormOptionsCacheProvider = Provider<ProfileFormOptionsCache>((ref) {
  return ProfileFormOptionsCache(FirebaseFirestore.instance);
});
