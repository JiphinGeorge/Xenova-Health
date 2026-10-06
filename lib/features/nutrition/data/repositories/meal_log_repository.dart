import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/meal_log_model.dart';

class MealLogRepository {
  MealLogRepository(this._firestoreService, this._firestore);

  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore;

  String _mealLogsPath(String userId) => 'users/$userId/meal_logs';

  Box<dynamic> get _mealBox => Hive.box<dynamic>(AppConstants.mealBox);

  Map<String, dynamic> _deepCastMap(dynamic map) {
    if (map is! Map) return {};
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _deepCastMap(value));
      } else if (value is List) {
        return MapEntry(
          key.toString(),
          value
              .map((item) => item is Map ? _deepCastMap(item) : item)
              .toList(),
        );
      }
      return MapEntry(key.toString(), value);
    });
  }

  List<MealLogModel> _getMealsFromHive(String userId, DateTime date) {
    try {
      final allValues = _mealBox.values;
      final meals = <MealLogModel>[];
      final targetDate = date.toLocal();

      for (final val in allValues) {
        if (val is Map) {
          try {
            final raw = _deepCastMap(val);
            final m = MealLogModel.fromJson(raw);
            final matchesUser = m.userId == userId ||
                userId == 'guest_user' ||
                m.userId == 'guest_user' ||
                userId.isEmpty ||
                m.userId.isEmpty;

            if (matchesUser) {
              final mDate = m.date.toLocal();
              if (mDate.year == targetDate.year &&
                  mDate.month == targetDate.month &&
                  mDate.day == targetDate.day) {
                meals.add(m);
              }
            }
          } catch (_) {
            // Skip individually corrupted meal records without failing whole list
          }
        }
      }
      meals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return meals;
    } catch (_) {
      return [];
    }
  }

  /// Watches all meal logs for a given user on a specific date.
  /// Emits instantly from local Hive box, updates reactively on additions,
  /// and syncs with Firestore in the background.
  Stream<List<MealLogModel>> watchMealLogsForDate(
    String userId,
    DateTime date,
  ) {
    late final StreamController<List<MealLogModel>> controller;

    StreamSubscription? hiveSub;
    StreamSubscription? firestoreSub;

    controller = StreamController<List<MealLogModel>>.broadcast(
      onListen: () {
        // 1. Emit Hive data immediately
        controller.add(_getMealsFromHive(userId, date));

        // 2. Listen to local Hive box modifications
        hiveSub = _mealBox.watch().listen((_) {
          if (!controller.isClosed) {
            controller.add(_getMealsFromHive(userId, date));
          }
        });

        // 3. Background Firestore sync
        try {
          final startOfDay = DateTime(date.year, date.month, date.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));

          firestoreSub = _firestore
              .collection(_mealLogsPath(userId))
              .where(
                'date',
                isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
              )
              .where('date', isLessThan: endOfDay.toIso8601String())
              .snapshots()
              .listen(
            (snapshot) {
              for (final doc in snapshot.docs) {
                final data = doc.data();
                _mealBox.put(doc.id, data);
              }
              if (!controller.isClosed) {
                controller.add(_getMealsFromHive(userId, date));
              }
            },
            onError: (_) {
              // Graceful offline fallback
            },
          );
        } catch (_) {}
      },
      onCancel: () {
        hiveSub?.cancel();
        firestoreSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Adds a new meal log locally and to Firestore.
  Future<void> addMealLog(MealLogModel mealLog) async {
    // 1. Persist immediately to Hive so UI updates instantly
    await _mealBox.put(mealLog.id, mealLog.toJson());

    // 2. Best-effort write to Firestore
    try {
      await _firestoreService
          .setDocument(
            path: '${_mealLogsPath(mealLog.userId)}/${mealLog.id}',
            data: mealLog.toJson(),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Offline fallback
    }
  }

  /// Deletes a meal log locally and from Firestore.
  Future<void> deleteMealLog(String userId, String mealId) async {
    await _mealBox.delete(mealId);

    try {
      await _firestoreService
          .deleteDocument('${_mealLogsPath(userId)}/$mealId')
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}

final mealLogRepositoryProvider = Provider<MealLogRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final firestore = FirebaseFirestore.instance;
  return MealLogRepository(firestoreService, firestore);
});
