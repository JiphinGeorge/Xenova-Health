import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/daily_nutrition_summary_model.dart';

class DailyNutritionRepository {
  DailyNutritionRepository(this._firestoreService, this._firestore);

  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore;

  String _summaryPath(String userId, String dateString) =>
      'users/$userId/daily_summaries/$dateString';

  /// Watches the daily nutrition summary for a specific date.
  Stream<DailyNutritionSummaryModel?> watchDailySummary(
    String userId,
    String dateString,
  ) {
    return _firestoreService
        .streamDocument(_summaryPath(userId, dateString))
        .map((doc) {
          if (!doc.exists) return null;
          return DailyNutritionSummaryModel.fromJson(doc.data()!);
        });
  }

  /// Sets or creates the initial daily summary document.
  Future<void> setDailySummary(DailyNutritionSummaryModel summary) async {
    await _firestoreService.setDocument(
      path: _summaryPath(summary.userId, summary.dateString),
      data: summary.toJson(),
    );
  }

  /// Transactionally updates the macros when a meal is added.
  /// If the document doesn't exist, it creates it using default targets.
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
    final docRef = _firestore.doc(_summaryPath(userId, dateString));

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        // Create initial empty document
        final initial = DailyNutritionSummaryModel(
          userId: userId,
          dateString: dateString,
          totalCalories: calories,
          totalProtein: protein,
          totalCarbs: carbs,
          totalFat: fat,
          totalFiber: fiber ?? 0.0,
          totalSugar: sugar ?? 0.0,
          totalSodium: sodium ?? 0.0,
          waterIntakeMl: 0,
          mealCount: 1,
          averageCaloriesPerMeal: calories,
          targetCalories: 2000, // Ideally pulled from User Profile later
          targetProtein: 150,
          targetCarbs: 200,
          targetFat: 65,
          waterGoalMl: 2500,
          remainingCalories: 2000 - calories,
          lastUpdated: DateTime.now(),
        );
        transaction.set(docRef, initial.toJson());
        return;
      }

      final currentData = snapshot.data()!;
      final currentCalories = (currentData['totalCalories'] as num).toDouble();
      final currentProtein = (currentData['totalProtein'] as num).toDouble();
      final currentCarbs = (currentData['totalCarbs'] as num).toDouble();
      final currentFat = (currentData['totalFat'] as num).toDouble();
      final currentFiber =
          (currentData['totalFiber'] as num?)?.toDouble() ?? 0.0;
      final currentSugar =
          (currentData['totalSugar'] as num?)?.toDouble() ?? 0.0;
      final currentSodium =
          (currentData['totalSodium'] as num?)?.toDouble() ?? 0.0;

      final targetCalories = (currentData['targetCalories'] as num?)?.toDouble() ?? 2000;
      final currentMealCount = (currentData['mealCount'] as num?)?.toInt() ?? 0;

      final newCals = currentCalories + calories;
      final newProtein = currentProtein + protein;
      final newMealCount = currentMealCount + 1;
      final averageCalories = newCals / newMealCount;

      // Simple AI signals logic
      final targetProtein = (currentData['targetProtein'] as num?)?.toDouble() ?? 150;
      final targetFiber = 30.0; // Hardcoded default
      
      final proteinMet = newProtein >= targetProtein;
      final calExceeded = newCals > targetCalories;
      final calMet = newCals >= (targetCalories - 100) && !calExceeded; // Within 100 kcal
      final fiberMet = (currentFiber + (fiber ?? 0.0)) >= targetFiber;

      transaction.update(docRef, {
        'totalCalories': newCals,
        'totalProtein': newProtein,
        'totalCarbs': currentCarbs + carbs,
        'totalFat': currentFat + fat,
        'totalFiber': currentFiber + (fiber ?? 0.0),
        'totalSugar': currentSugar + (sugar ?? 0.0),
        'totalSodium': currentSodium + (sodium ?? 0.0),
        'mealCount': newMealCount,
        'averageCaloriesPerMeal': averageCalories,
        'remainingCalories': (targetCalories - newCals).clamp(0.0, double.infinity),
        'proteinTargetMet': proteinMet,
        'calorieTargetExceeded': calExceeded,
        'calorieTargetMet': calMet,
        'fiberGoalMet': fiberMet,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    });
  }

  /// Transactionally updates the macros when a meal is removed.
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
    final docRef = _firestore.doc(_summaryPath(userId, dateString));

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final currentData = snapshot.data()!;
      final currentCalories = (currentData['totalCalories'] as num).toDouble();
      final currentProtein = (currentData['totalProtein'] as num).toDouble();
      final currentCarbs = (currentData['totalCarbs'] as num).toDouble();
      final currentFat = (currentData['totalFat'] as num).toDouble();
      final currentFiber =
          (currentData['totalFiber'] as num?)?.toDouble() ?? 0.0;
      final currentSugar =
          (currentData['totalSugar'] as num?)?.toDouble() ?? 0.0;
      final currentSodium =
          (currentData['totalSodium'] as num?)?.toDouble() ?? 0.0;

      final targetCalories = (currentData['targetCalories'] as num?)?.toDouble() ?? 2000;
      final currentMealCount = (currentData['mealCount'] as num?)?.toInt() ?? 1;

      final newCals = (currentCalories - calories).clamp(0.0, double.infinity);
      final newProtein = (currentProtein - protein).clamp(0.0, double.infinity);
      final newMealCount = (currentMealCount - 1).clamp(0, 100);
      final averageCalories = newMealCount > 0 ? newCals / newMealCount : 0.0;

      final targetProtein = (currentData['targetProtein'] as num?)?.toDouble() ?? 150;
      final targetFiber = 30.0;
      
      final proteinMet = newProtein >= targetProtein;
      final calExceeded = newCals > targetCalories;
      final calMet = newCals >= (targetCalories - 100) && !calExceeded;
      final newFiber = (currentFiber - (fiber ?? 0.0)).clamp(0.0, double.infinity);
      final fiberMet = newFiber >= targetFiber;

      transaction.update(docRef, {
        'totalCalories': newCals,
        'totalProtein': newProtein,
        'totalCarbs': (currentCarbs - carbs).clamp(0.0, double.infinity),
        'totalFat': (currentFat - fat).clamp(0.0, double.infinity),
        'totalFiber': newFiber,
        'totalSugar': (currentSugar - (sugar ?? 0.0)).clamp(0.0, double.infinity),
        'totalSodium': (currentSodium - (sodium ?? 0.0)).clamp(0.0, double.infinity),
        'mealCount': newMealCount,
        'averageCaloriesPerMeal': averageCalories,
        'remainingCalories': (targetCalories - newCals).clamp(0.0, double.infinity),
        'proteinTargetMet': proteinMet,
        'calorieTargetExceeded': calExceeded,
        'calorieTargetMet': calMet,
        'fiberGoalMet': fiberMet,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    });
  }

  /// Updates the water intake directly.
  Future<void> updateWaterIntake(
    String userId,
    String dateString,
    int amountMl,
  ) async {
    final docRef = _firestore.doc(_summaryPath(userId, dateString));

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        // Create initial empty document just for water if needed
        final initial = DailyNutritionSummaryModel(
          userId: userId,
          dateString: dateString,
          totalCalories: 0,
          totalProtein: 0,
          totalCarbs: 0,
          totalFat: 0,
          waterIntakeMl: amountMl > 0 ? amountMl : 0,
          targetCalories: 2000,
          waterGoalMl: 2500,
          lastUpdated: DateTime.now(),
        );
        transaction.set(docRef, initial.toJson());
        return;
      }

      final currentData = snapshot.data()!;
      final currentWater = (currentData['waterIntakeMl'] as num).toInt();
      final waterGoal = (currentData['waterGoalMl'] as num?)?.toInt() ?? 2500;

      final newWater = (currentWater + amountMl).clamp(0, 10000); // Max 10L

      transaction.update(docRef, {
        'waterIntakeMl': newWater,
        'waterGoalMet': newWater >= waterGoal,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    });
  }

  /// Gets the nutrition summaries for a given date range.
  Future<List<DailyNutritionSummaryModel>> getNutritionSummaryForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startString = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endString = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    final snapshot = await _firestore
        .collection('users/$userId/daily_summaries')
        .where('dateString', isGreaterThanOrEqualTo: startString)
        .where('dateString', isLessThanOrEqualTo: endString)
        .get();

    return snapshot.docs
        .map((doc) => DailyNutritionSummaryModel.fromJson(doc.data()))
        .toList();
  }
}

final dailyNutritionRepositoryProvider = Provider<DailyNutritionRepository>((
  ref,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final firestore = FirebaseFirestore.instance;
  return DailyNutritionRepository(firestoreService, firestore);
});
