import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/daily_nutrition_summary_model.dart';

class DailyNutritionRepository {
  DailyNutritionRepository(this._firestoreService, this._firestore);

  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore;

  String _summaryPath(String userId, String dateString) =>
      'users/$userId/daily_summaries/$dateString';

  Box<dynamic> get _summaryBox =>
      Hive.box<dynamic>(AppConstants.dailySummaryBox);

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

  DailyNutritionSummaryModel? _safeParseSummary(
    dynamic val,
    String userId,
    String dateString,
  ) {
    if (val is! Map) return null;
    try {
      final raw = _deepCastMap(val);
      raw['userId'] = raw['userId'] ?? userId;
      raw['dateString'] = raw['dateString'] ?? dateString;
      raw['totalCalories'] =
          (raw['totalCalories'] as num?)?.toDouble() ?? 0.0;
      raw['totalProtein'] =
          (raw['totalProtein'] as num?)?.toDouble() ?? 0.0;
      raw['totalCarbs'] =
          (raw['totalCarbs'] as num?)?.toDouble() ?? 0.0;
      raw['totalFat'] = (raw['totalFat'] as num?)?.toDouble() ?? 0.0;
      raw['waterIntakeMl'] =
          (raw['waterIntakeMl'] as num?)?.toInt() ?? 0;
      raw['mealCount'] = (raw['mealCount'] as num?)?.toInt() ?? 0;
      raw['targetCalories'] =
          (raw['targetCalories'] as num?)?.toDouble() ?? 2000.0;
      raw['lastUpdated'] =
          raw['lastUpdated'] ?? DateTime.now().toIso8601String();
      return DailyNutritionSummaryModel.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  DailyNutritionSummaryModel? _getFromHive(String userId, String dateString) {
    try {
      final key = '${userId}_$dateString';
      final val = _summaryBox.get(key) ??
          _summaryBox.get(dateString) ??
          _summaryBox.get('guest_user_$dateString');
      return _safeParseSummary(val, userId, dateString);
    } catch (_) {
      return null;
    }
  }

  /// Watches the daily nutrition summary for a specific date.
  /// Emits instantly from local Hive, updates reactively, and syncs Firestore in background.
  Stream<DailyNutritionSummaryModel?> watchDailySummary(
    String userId,
    String dateString,
  ) {
    late final StreamController<DailyNutritionSummaryModel?> controller;
    StreamSubscription<dynamic>? hiveSub;
    StreamSubscription<dynamic>? firestoreSub;

    controller = StreamController<DailyNutritionSummaryModel?>.broadcast(
      onListen: () {
        // 1. Emit Hive data immediately
        controller.add(_getFromHive(userId, dateString));

        // 2. Listen to Hive changes
        hiveSub = _summaryBox.watch().listen((_) {
          if (!controller.isClosed) {
            controller.add(_getFromHive(userId, dateString));
          }
        });

        // 3. Background Firestore sync
        try {
          firestoreSub = _firestoreService
              .streamDocument(_summaryPath(userId, dateString))
              .listen(
            (doc) {
              if (doc.exists && doc.data() != null) {
                final data = doc.data()!;
                _summaryBox.put('${userId}_$dateString', data);
                _summaryBox.put(dateString, data);
                if (!controller.isClosed) {
                  final parsed =
                      _safeParseSummary(data, userId, dateString);
                  if (parsed != null) controller.add(parsed);
                }
              }
            },
            onError: (_) {},
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

  /// Sets or creates the initial daily summary document.
  Future<void> setDailySummary(DailyNutritionSummaryModel summary) async {
    final key = '${summary.userId}_${summary.dateString}';
    await _summaryBox.put(key, summary.toJson());
    await _summaryBox.put(summary.dateString, summary.toJson());

    try {
      await _firestoreService
          .setDocument(
            path: _summaryPath(summary.userId, summary.dateString),
            data: summary.toJson(),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Updates the macros when a meal is added.
  Future<void> addMacros(
    String userId,
    String dateString, {
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fiber,
    double? sugar,
    double? sodium,
  }) async {
    final current = _getFromHive(userId, dateString);

    final currentCalories = current?.totalCalories ?? 0.0;
    final currentProtein = current?.totalProtein ?? 0.0;
    final currentCarbs = current?.totalCarbs ?? 0.0;
    final currentFat = current?.totalFat ?? 0.0;
    final currentFiber = current?.totalFiber ?? 0.0;
    final currentSugar = current?.totalSugar ?? 0.0;
    final currentSodium = current?.totalSodium ?? 0.0;
    final currentMealCount = current?.mealCount ?? 0;
    final targetCalories = current?.targetCalories ?? 2000.0;
    final targetProtein = current?.targetProtein ?? 150.0;

    final newCals = currentCalories + calories;
    final newProtein = currentProtein + protein;
    final newCarbs = currentCarbs + carbs;
    final newFat = currentFat + fat;
    final newFiber = currentFiber + (fiber ?? 0.0);
    final newSugar = currentSugar + (sugar ?? 0.0);
    final newSodium = currentSodium + (sodium ?? 0.0);
    final newMealCount = currentMealCount + 1;
    final avgCals = newMealCount > 0 ? newCals / newMealCount : newCals;

    final proteinMet = newProtein >= targetProtein;
    final calExceeded = newCals > targetCalories;
    final calMet = newCals >= (targetCalories - 100) && !calExceeded;
    final fiberMet = newFiber >= 30.0;

    final updated = DailyNutritionSummaryModel(
      userId: userId,
      dateString: dateString,
      totalCalories: newCals,
      totalProtein: newProtein,
      totalCarbs: newCarbs,
      totalFat: newFat,
      totalFiber: newFiber,
      totalSugar: newSugar,
      totalSodium: newSodium,
      waterIntakeMl: current?.waterIntakeMl ?? 0,
      mealCount: newMealCount,
      averageCaloriesPerMeal: avgCals,
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: current?.targetCarbs ?? 200.0,
      targetFat: current?.targetFat ?? 65.0,
      waterGoalMl: current?.waterGoalMl ?? 2500,
      remainingCalories: (targetCalories - newCals).clamp(0.0, double.infinity),
      proteinTargetMet: proteinMet,
      calorieTargetExceeded: calExceeded,
      calorieTargetMet: calMet,
      fiberGoalMet: fiberMet,
      lastUpdated: DateTime.now(),
    );

    // Save locally to Hive immediately so UI updates without network latency
    await setDailySummary(updated);
  }

  /// Updates the macros when a meal is removed.
  Future<void> removeMacros(
    String userId,
    String dateString, {
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fiber,
    double? sugar,
    double? sodium,
  }) async {
    final current = _getFromHive(userId, dateString);
    if (current == null) return;

    final currentCalories = current.totalCalories;
    final currentProtein = current.totalProtein;
    final currentCarbs = current.totalCarbs;
    final currentFat = current.totalFat;
    final currentFiber = current.totalFiber ?? 0.0;
    final currentSugar = current.totalSugar ?? 0.0;
    final currentSodium = current.totalSodium ?? 0.0;
    final currentMealCount = current.mealCount;
    final targetCalories = current.targetCalories;
    final targetProtein = current.targetProtein ?? 150.0;

    final newCals = (currentCalories - calories).clamp(0.0, double.infinity);
    final newProtein = (currentProtein - protein).clamp(0.0, double.infinity);
    final newCarbs = (currentCarbs - carbs).clamp(0.0, double.infinity);
    final newFat = (currentFat - fat).clamp(0.0, double.infinity);
    final newFiber = (currentFiber - (fiber ?? 0.0)).clamp(0.0, double.infinity);
    final newSugar = (currentSugar - (sugar ?? 0.0)).clamp(0.0, double.infinity);
    final newSodium = (currentSodium - (sodium ?? 0.0)).clamp(0.0, double.infinity);
    final newMealCount = (currentMealCount - 1).clamp(0, 100);
    final avgCals = newMealCount > 0 ? newCals / newMealCount : 0.0;

    final proteinMet = newProtein >= targetProtein;
    final calExceeded = newCals > targetCalories;
    final calMet = newCals >= (targetCalories - 100) && !calExceeded;
    final fiberMet = newFiber >= 30.0;

    final updated = DailyNutritionSummaryModel(
      userId: userId,
      dateString: dateString,
      totalCalories: newCals,
      totalProtein: newProtein,
      totalCarbs: newCarbs,
      totalFat: newFat,
      totalFiber: newFiber,
      totalSugar: newSugar,
      totalSodium: newSodium,
      waterIntakeMl: current.waterIntakeMl,
      mealCount: newMealCount,
      averageCaloriesPerMeal: avgCals,
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: current.targetCarbs ?? 200.0,
      targetFat: current.targetFat ?? 65.0,
      waterGoalMl: current.waterGoalMl ?? 2500,
      remainingCalories: (targetCalories - newCals).clamp(0.0, double.infinity),
      proteinTargetMet: proteinMet,
      calorieTargetExceeded: calExceeded,
      calorieTargetMet: calMet,
      fiberGoalMet: fiberMet,
      lastUpdated: DateTime.now(),
    );

    await setDailySummary(updated);
  }

  /// Updates the water intake directly.
  Future<void> updateWaterIntake(
    String userId,
    String dateString,
    int amountMl,
  ) async {
    final current = _getFromHive(userId, dateString);
    final currentWater = current?.waterIntakeMl ?? 0;
    final waterGoal = current?.waterGoalMl ?? 2500;
    final newWater = (currentWater + amountMl).clamp(0, 10000);

    final updated = (current ??
            DailyNutritionSummaryModel(
              userId: userId,
              dateString: dateString,
              totalCalories: 0,
              totalProtein: 0,
              totalCarbs: 0,
              totalFat: 0,
              waterIntakeMl: 0,
              targetCalories: 2000,
              lastUpdated: DateTime.now(),
            ))
        .copyWith(
      waterIntakeMl: newWater,
      waterGoalMet: newWater >= waterGoal,
      lastUpdated: DateTime.now(),
    );

    await setDailySummary(updated);
  }

  /// Gets the nutrition summaries for a given date range.
  Future<List<DailyNutritionSummaryModel>> getNutritionSummaryForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startString =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endString =
        '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    try {
      final snapshot = await _firestore
          .collection('users/$userId/daily_summaries')
          .where('dateString', isGreaterThanOrEqualTo: startString)
          .where('dateString', isLessThanOrEqualTo: endString)
          .get();

      return snapshot.docs
          .map((doc) => DailyNutritionSummaryModel.fromJson(doc.data()))
          .toList();
    } catch (_) {
      // Local Hive fallback
      final result = <DailyNutritionSummaryModel>[];
      for (var d = startDate;
          !d.isAfter(endDate);
          d = d.add(const Duration(days: 1))) {
        final dStr =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final summary = _getFromHive(userId, dStr);
        if (summary != null) result.add(summary);
      }
      return result;
    }
  }
}

final dailyNutritionRepositoryProvider = Provider<DailyNutritionRepository>((
  ref,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final firestore = FirebaseFirestore.instance;
  return DailyNutritionRepository(firestoreService, firestore);
});
