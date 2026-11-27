import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../users/presentation/providers/users_providers.dart';
import '../../data/maintenance_bill_repository.dart';
import '../../data/maintenance_cost_repository.dart';
import '../../data/purchases_repository.dart';

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepository(
    FirebaseFirestore.instance,
    ref.watch(usersRepositoryProvider),
  );
});

final maintenanceBillRepositoryProvider = Provider<MaintenanceBillRepository>((ref) {
  return MaintenanceBillRepository(FirebaseFirestore.instance);
});

final maintenanceCostRepositoryProvider = Provider<MaintenanceCostRepository>((ref) {
  return MaintenanceCostRepository(
    FirebaseFirestore.instance,
    ref.watch(maintenanceBillRepositoryProvider),
  );
});
