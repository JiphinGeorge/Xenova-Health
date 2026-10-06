import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/lifetime_stats_model.dart';

class LifetimeStatsRepository {
  LifetimeStatsRepository(this._firestoreService);

  final FirestoreService _firestoreService;
  final _statsController = StreamController<LifetimeStatsModel>.broadcast();

  String _documentPath(String userId) => 'users/$userId/stats/lifetime';
  String _cacheKey(String userId) => 'lifetime_stats_$userId';

  LifetimeStatsModel _loadLocal(String userId) {
    if (Hive.isBoxOpen(AppConstants.cacheBox)) {
      try {
        final raw = Hive.box<dynamic>(
          AppConstants.cacheBox,
        ).get(_cacheKey(userId));
        if (raw != null) {
          return LifetimeStatsModel.fromJson(
            Map<String, dynamic>.from(raw as Map),
          );
        }
      } catch (_) {}
    }
    return LifetimeStatsModel(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveLocal(String userId, LifetimeStatsModel stats) async {
    if (Hive.isBoxOpen(AppConstants.cacheBox)) {
      try {
        await Hive.box<dynamic>(
          AppConstants.cacheBox,
        ).put(_cacheKey(userId), stats.toJson());
        _statsController.add(stats);
      } catch (_) {}
    }
  }

  Future<LifetimeStatsModel> getStats(String userId) async {
    try {
      final doc = await _firestoreService.getDocument(_documentPath(userId));
      if (doc.exists && doc.data() != null) {
        final stats = LifetimeStatsModel.fromJson(doc.data()!);
        await _saveLocal(userId, stats);
        return stats;
      }
    } catch (_) {}
    return _loadLocal(userId);
  }

  Future<void> saveStats(String userId, LifetimeStatsModel stats) async {
    final updatedStats = stats.copyWith(updatedAt: DateTime.now());
    await _saveLocal(userId, updatedStats);
    try {
      await _firestoreService.setDocument(
        path: _documentPath(userId),
        data: updatedStats.toJson(),
      );
    } catch (_) {}
  }

  Stream<LifetimeStatsModel> watchStats(String userId) {
    late final StreamController<LifetimeStatsModel> controller;
    StreamSubscription<LifetimeStatsModel>? localSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? firestoreSub;

    controller = StreamController<LifetimeStatsModel>(
      onListen: () {
        controller.add(_loadLocal(userId));
        localSub = _statsController.stream.listen((s) {
          if (!controller.isClosed) controller.add(s);
        });

        try {
          firestoreSub = FirebaseFirestore.instance
              .doc(_documentPath(userId))
              .snapshots()
              .listen(
                (doc) {
                  if (doc.exists && doc.data() != null) {
                    final s = LifetimeStatsModel.fromJson(doc.data()!);
                    _saveLocal(userId, s);
                  }
                },
                onError: (_) {},
              );
        } catch (_) {}
      },
      onCancel: () {
        localSub?.cancel();
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }
}

final lifetimeStatsRepositoryProvider = Provider<LifetimeStatsRepository>((
  ref,
) {
  return LifetimeStatsRepository(ref.watch(firestoreServiceProvider));
});

final lifetimeStatsStreamProvider = StreamProvider<LifetimeStatsModel>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(lifetimeStatsRepositoryProvider).watchStats(user.uid);
});
