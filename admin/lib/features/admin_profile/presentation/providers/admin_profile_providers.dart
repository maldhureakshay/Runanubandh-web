import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/admin_profile.dart';
import '../../data/admin_profile_repository.dart';

final adminProfileRepositoryProvider = Provider<AdminProfileRepository>((ref) {
  return AdminProfileRepository(FirebaseFirestore.instance);
});

/// Profile for the currently signed-in admin (name, client, commission).
final currentAdminProfileProvider =
    FutureProvider.autoDispose<AdminProfile>((ref) async {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    throw StateError('Not signed in');
  }
  final repo = ref.watch(adminProfileRepositoryProvider);
  return repo.fetchForUser(user.uid);
});
