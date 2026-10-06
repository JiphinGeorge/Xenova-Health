import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/dashboard_stats_model.dart';

/// Repository for managing the lightweight dashboard stats cache.
class DashboardStatsRepository {
  DashboardStatsRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  String _documentPath(String userId) => 'users/$userId/stats/overview';
  String _cacheKey(String userId) => 'dashboard_stats_$userId';

  /// Updates the dashboard stats overview document.
  Future<void> updateStats(String userId, DashboardStatsModel stats) async {
    final Map<String, dynamic> data = stats.toJson();
    if (stats.aiStats != null) {
      data['aiStats'] = stats.aiStats!.toJson();
    }
    if (stats.healthScore != null) {
      data['healthScore'] = stats.healthScore!.toJson();
    }

    // 1. Save to local Hive cache immediately for offline resilience
    try {
      if (Hive.isBoxOpen(AppConstants.cacheBox)) {
        final box = Hive.box<dynamic>(AppConstants.cacheBox);
        await box.put(_cacheKey(userId), jsonEncode(data));
      }
    } catch (_) {}

    // 2. Sync to Firestore in background
    try {
      await _firestoreService.setDocument(
        path: _documentPath(userId),
        data: data,
      );
    } catch (_) {}
  }

  /// Streams the dashboard stats overview document with local fallback.
  Stream<DashboardStatsModel?> watchStats(String userId) {
    return _firestoreService.streamDocument(_documentPath(userId)).map((doc) {
      if (doc.exists && doc.data() != null) {
        final stats = DashboardStatsModel.fromJson(doc.data()!);
        // Refresh local cache
        try {
          if (Hive.isBoxOpen(AppConstants.cacheBox)) {
            final box = Hive.box<dynamic>(AppConstants.cacheBox);
            box.put(_cacheKey(userId), jsonEncode(stats.toJson()));
          }
        } catch (_) {}
        return stats;
      }

      // Fallback to local Hive cache if remote doc doesn't exist yet
      try {
        if (Hive.isBoxOpen(AppConstants.cacheBox)) {
          final box = Hive.box<dynamic>(AppConstants.cacheBox);
          final cached = box.get(_cacheKey(userId));
          if (cached != null) {
            final map = cached is String
                ? jsonDecode(cached) as Map<String, dynamic>
                : Map<String, dynamic>.from(cached as Map);
            return DashboardStatsModel.fromJson(map);
          }
        }
      } catch (_) {}

      return null;
    });
  }

  /// Gets the dashboard stats overview document once.
  Future<DashboardStatsModel?> getStats(String userId) async {
    try {
      final doc = await _firestoreService.getDocument(_documentPath(userId));
      if (doc.exists && doc.data() != null) {
        return DashboardStatsModel.fromJson(doc.data()!);
      }
    } catch (_) {}

    // Fallback to local Hive cache
    try {
      if (Hive.isBoxOpen(AppConstants.cacheBox)) {
        final box = Hive.box<dynamic>(AppConstants.cacheBox);
        final cached = box.get(_cacheKey(userId));
        if (cached != null) {
          final map = cached is String
              ? jsonDecode(cached) as Map<String, dynamic>
              : Map<String, dynamic>.from(cached as Map);
          return DashboardStatsModel.fromJson(map);
        }
      }
    } catch (_) {}

    return null;
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
