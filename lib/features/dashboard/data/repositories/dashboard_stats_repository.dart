import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/dashboard_stats_model.dart';

/// Repository for managing the lightweight dashboard stats cache.
class DashboardStatsRepository {
  DashboardStatsRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  String _documentPath(String userId) => 'users/$userId/stats/overview';

  /// Updates the dashboard stats overview document.
  Future<void> updateStats(String userId, DashboardStatsModel stats) async {
    final Map<String, dynamic> data = stats.toJson();
    if (stats.aiStats != null) {
      data['aiStats'] = stats.aiStats!.toJson();
    }
    if (stats.healthScore != null) {
      data['healthScore'] = stats.healthScore!.toJson();
    }

    await _firestoreService.setDocument(
      path: _documentPath(userId),
      data: data,
    );
  }

  /// Streams the dashboard stats overview document.
  Stream<DashboardStatsModel?> watchStats(String userId) {
    return _firestoreService.streamDocument(_documentPath(userId)).map((doc) {
      if (!doc.exists) return null;
      return DashboardStatsModel.fromJson(doc.data()!);
    });
  }

  /// Gets the dashboard stats overview document once.
  Future<DashboardStatsModel?> getStats(String userId) async {
    final doc = await _firestoreService.getDocument(_documentPath(userId));
    if (!doc.exists) return null;
    return DashboardStatsModel.fromJson(doc.data()!);
  }
}

final dashboardStatsRepositoryProvider = Provider<DashboardStatsRepository>((
  ref,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return DashboardStatsRepository(firestoreService);
});

/// Provider for watching the DashboardStatsModel directly.
final dashboardStatsStreamProvider = StreamProvider<DashboardStatsModel?>((
  ref,
) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(dashboardStatsRepositoryProvider).watchStats(user.uid);
});
