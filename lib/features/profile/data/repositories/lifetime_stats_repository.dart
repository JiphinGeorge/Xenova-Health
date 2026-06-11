import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/lifetime_stats_model.dart';

class LifetimeStatsRepository {
  LifetimeStatsRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  String _documentPath(String userId) => 'users/$userId/stats/lifetime';

  Future<LifetimeStatsModel> getStats(String userId) async {
    final doc = await _firestoreService.getDocument(_documentPath(userId));
    if (doc.exists && doc.data() != null) {
      return LifetimeStatsModel.fromJson(doc.data()!);
    }
    return LifetimeStatsModel(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> saveStats(String userId, LifetimeStatsModel stats) async {
    final updatedStats = stats.copyWith(updatedAt: DateTime.now());
    await _firestoreService.setDocument(
      path: _documentPath(userId),
      data: updatedStats.toJson(),
    );
  }

  Stream<LifetimeStatsModel> watchStats(String userId) {
    return FirebaseFirestore.instance
        .doc(_documentPath(userId))
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return LifetimeStatsModel.fromJson(doc.data()!);
      }
      return LifetimeStatsModel(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }
}

final lifetimeStatsRepositoryProvider = Provider<LifetimeStatsRepository>((ref) {
  return LifetimeStatsRepository(ref.watch(firestoreServiceProvider));
});

final lifetimeStatsStreamProvider = StreamProvider<LifetimeStatsModel>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(lifetimeStatsRepositoryProvider).watchStats(user.uid);
});
