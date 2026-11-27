import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(FirebaseFirestore.instance);
});

/// Cutoff for the "Active users created after …" card.
/// Currently set to **14 Jan 2026** (most recent 14 Jan from today's date).
/// Change in one place — both the count and the card label use it.
final activeUsersCutoffProvider = Provider<DateTime>((ref) {
  return DateTime(2026, 2, 09);
});

/// Cached fetch of all metrics. Trigger a manual refresh from UI with:
///   ref.invalidate(dashboardMetricsProvider);
final dashboardMetricsProvider =
    FutureProvider.autoDispose<DashboardMetrics>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final cutoff = ref.watch(activeUsersCutoffProvider);
  return repo.fetchAll(activeSinceCutoff: cutoff);
});
