import 'package:cloud_firestore/cloud_firestore.dart';

/// Efficient admin dashboard reads.
///
/// Uses Firestore **count aggregates** so each metric is **1 document read**
/// regardless of collection size. Source-of-truth field names mirror the
/// mobile app:
///   * `users.status`   — boolean (true = active)
///   * `profiles.active` — boolean (true = active)
class DashboardRepository {
  DashboardRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<int> totalUsers() async {
    final agg = await _firestore.collection('users').count().get();
    return agg.count ?? 0;
  }

  Future<int> activeUsers() async {
    final agg = await _firestore
        .collection('users')
        .where('status', isEqualTo: true)
        .count()
        .get();
    return agg.count ?? 0;
  }

  Future<int> totalProfiles() async {
    final agg = await _firestore.collection('profiles').count().get();
    return agg.count ?? 0;
  }

  Future<int> activeProfiles() async {
    final agg = await _firestore
        .collection('profiles')
        .where('active', isEqualTo: true)
        .count()
        .get();
    return agg.count ?? 0;
  }

  /// Active users (`status == true`) with `createdAt >= cutoff`.
  /// May require a composite index on (`status`, `createdAt`) the first time
  /// it is called — Firestore returns a console link in the error if so.
  Future<int> activeUsersCreatedAfter(DateTime cutoff) async {
    final agg = await _firestore
        .collection('users')
        .where('status', isEqualTo: true)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .count()
        .get();
    return agg.count ?? 0;
  }

  Future<DashboardMetrics> fetchAll({required DateTime activeSinceCutoff}) async {
    final results = await Future.wait([
      totalUsers(),
      activeUsers(),
      totalProfiles(),
      activeProfiles(),
      activeUsersCreatedAfter(activeSinceCutoff),
    ]);
    return DashboardMetrics(
      totalUsers: results[0],
      activeUsers: results[1],
      totalProfiles: results[2],
      activeProfiles: results[3],
      activeUsersSinceCutoff: results[4],
      activeSinceCutoff: activeSinceCutoff,
      fetchedAt: DateTime.now(),
    );
  }
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalProfiles,
    required this.activeProfiles,
    required this.activeUsersSinceCutoff,
    required this.activeSinceCutoff,
    required this.fetchedAt,
  });

  final int totalUsers;
  final int activeUsers;
  final int totalProfiles;
  final int activeProfiles;
  final int activeUsersSinceCutoff;
  final DateTime activeSinceCutoff;
  final DateTime fetchedAt;

  double get usersActiveRatio =>
      totalUsers == 0 ? 0 : activeUsers / totalUsers;
  double get profilesActiveRatio =>
      totalProfiles == 0 ? 0 : activeProfiles / totalProfiles;
  double get newCohortRatio =>
      activeUsers == 0 ? 0 : activeUsersSinceCutoff / activeUsers;
}
