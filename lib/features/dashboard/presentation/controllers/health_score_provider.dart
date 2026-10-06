import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../fasting/presentation/controllers/fasting_controller.dart';
import '../../../nutrition/presentation/controllers/nutrition_controller.dart';
import '../../../weight/presentation/controllers/weight_controller.dart';
import '../../data/repositories/dashboard_stats_repository.dart';
import '../../domain/models/dashboard_stats_model.dart';
import '../../domain/models/health_score_model.dart';

/// Dynamic Health Score Engine.
/// Calculates a responsive, 4-pillar composite health score (0-100):
/// 1. Nutrition & Calorie/Protein Balance (35%)
/// 2. Fasting Routine & Streaks (25%)
/// 3. Weight Tracking & Consistency (25%)
/// 4. Daily Hydration (15%)
final healthScoreProvider = Provider<HealthScoreModel>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final nutritionSummary = ref.watch(dailyNutritionSummaryStreamProvider).value;
  final fastingMetrics = ref.watch(fastingMetricsProvider);
  final activeFast = ref.watch(activeFastingSessionProvider).value;
  final weightMetrics = ref.watch(weightMetricsProvider);
  final weightEntries = ref.watch(weightEntriesStreamProvider).value;

  // ─────────────────────────────────────────────────────────────
  // 1. NUTRITION SCORE (0 - 100, Weight: 35%)
  // ─────────────────────────────────────────────────────────────
  double nutritionScore = 65.0; // Encouraging default baseline
  if (nutritionSummary != null) {
    final mealCount = nutritionSummary.mealCount;
    final totalCals = nutritionSummary.totalCalories;
    final targetCals = nutritionSummary.targetCalories > 0
        ? nutritionSummary.targetCalories
        : 2000.0;
    final totalProtein = nutritionSummary.totalProtein;
    final targetProtein = nutritionSummary.targetProtein > 0
        ? nutritionSummary.targetProtein
        : 140.0;

    if (mealCount > 0) {
      final calRatio = totalCals / targetCals;
      double calScore;
      if (calRatio >= 0.85 && calRatio <= 1.15) {
        calScore = 95.0 - ((calRatio - 1.0).abs() * 80.0);
      } else if (calRatio >= 0.60 && calRatio < 0.85) {
        calScore = 70.0 + ((calRatio - 0.60) / 0.25) * 20.0;
      } else if (calRatio >= 0.30 && calRatio < 0.60) {
        calScore = 50.0 + ((calRatio - 0.30) / 0.30) * 20.0;
      } else if (calRatio < 0.30) {
        calScore = 40.0 + (calRatio / 0.30) * 10.0;
      } else {
        // Exceeded 1.15
        calScore = (90.0 - ((calRatio - 1.15) * 60.0)).clamp(35.0, 90.0);
      }

      final proteinRatio = (totalProtein / targetProtein).clamp(0.0, 1.2);
      double proteinScore;
      if (proteinRatio >= 0.85) {
        proteinScore = 95.0;
      } else if (proteinRatio >= 0.60) {
        proteinScore = 80.0;
      } else {
        proteinScore = 40.0 + (proteinRatio * 50.0);
      }

      final mealBonus = (mealCount >= 3) ? 5.0 : (mealCount == 2 ? 3.0 : 0.0);
      nutritionScore =
          ((calScore * 0.65) + (proteinScore * 0.35) + mealBonus).clamp(0.0, 100.0);
    } else {
      if (activeFast != null) {
        nutritionScore = 75.0; // Fasting in progress, nutrition on hold intentionally
      } else {
        nutritionScore = 60.0;
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2. FASTING SCORE (0 - 100, Weight: 25%)
  // ─────────────────────────────────────────────────────────────
  double fastingScore = 60.0;
  if (activeFast != null) {
    final elapsed = DateTime.now().difference(activeFast.startTime);
    final targetMins = (activeFast.targetDurationHours * 60).toInt();
    if (targetMins > 0) {
      final progress = (elapsed.inMinutes / targetMins).clamp(0.0, 1.0);
      if (elapsed.inMinutes >= targetMins) {
        fastingScore = 100.0;
      } else {
        fastingScore = 60.0 + (progress * 35.0);
      }
    } else {
      fastingScore = 75.0;
    }
  } else {
    final streak = fastingMetrics.currentStreakDays;
    if (streak >= 5) {
      fastingScore = 95.0;
    } else if (streak >= 3) {
      fastingScore = 88.0;
    } else if (streak >= 1) {
      fastingScore = 78.0;
    } else {
      if (fastingMetrics.weeklyFasts >= 3) {
        fastingScore = 82.0;
      } else if (fastingMetrics.weeklyFasts >= 1) {
        fastingScore = 72.0;
      } else {
        fastingScore = 60.0;
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. WEIGHT & CONSISTENCY SCORE (0 - 100, Weight: 25%)
  // ─────────────────────────────────────────────────────────────
  double consistencyPts = 35.0;
  if (weightEntries != null && weightEntries.isNotEmpty) {
    final now = DateTime.now();
    final latestDate = weightEntries.first.date;
    final daysSince = now.difference(latestDate).inDays;
    if (daysSince <= 3) {
      consistencyPts = 50.0;
    } else if (daysSince <= 7) {
      consistencyPts = 42.0;
    } else if (daysSince <= 14) {
      consistencyPts = 35.0;
    } else {
      consistencyPts = 25.0;
    }
  } else {
    consistencyPts = 35.0;
  }

  double healthMetricPts = 35.0;
  final bmi = weightMetrics.bmi;
  if (bmi != null && bmi > 0) {
    if (bmi >= 18.5 && bmi <= 24.9) {
      healthMetricPts = 45.0; // Optimal BMI
    } else if (bmi >= 25.0 && bmi <= 29.9) {
      healthMetricPts = 38.0; // Overweight
    } else if (bmi >= 30.0) {
      healthMetricPts = 30.0;
    } else {
      healthMetricPts = 32.0; // Underweight
    }
  }

  final goalProgress = weightMetrics.goalProgressPercentage ?? 0.0;
  final goalBonus = (goalProgress * 8.0).clamp(0.0, 8.0);
  final weightConsistencyScore =
      (consistencyPts + healthMetricPts + goalBonus).clamp(0.0, 100.0);

  // ─────────────────────────────────────────────────────────────
  // 4. WATER / HYDRATION SCORE (0 - 100, Weight: 15%)
  // ─────────────────────────────────────────────────────────────
  double waterScore = 55.0;
  final waterGoal =
      nutritionSummary?.waterGoalMl ?? user?.dailyWaterGoalMl ?? 2500;
  final waterIntake = nutritionSummary?.waterIntakeMl ?? 0;
  if (waterGoal > 0) {
    final waterRatio = (waterIntake / waterGoal).clamp(0.0, 1.5);
    if (waterRatio >= 1.0) {
      waterScore = 100.0;
    } else if (waterRatio >= 0.75) {
      waterScore = 85.0 + ((waterRatio - 0.75) / 0.25) * 15.0;
    } else if (waterRatio >= 0.50) {
      waterScore = 70.0 + ((waterRatio - 0.50) / 0.25) * 15.0;
    } else if (waterRatio > 0.0) {
      waterScore = 40.0 + (waterRatio / 0.50) * 30.0;
    } else {
      waterScore = 50.0;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // COMPOSITE OVERALL HEALTH SCORE
  // ─────────────────────────────────────────────────────────────
  final overall = (
    nutritionScore * 0.35 +
    fastingScore * 0.25 +
    weightConsistencyScore * 0.25 +
    waterScore * 0.15
  ).roundToDouble().clamp(0.0, 100.0);

  return HealthScoreModel(
    nutritionScore: nutritionScore.roundToDouble(),
    fastingScore: fastingScore.roundToDouble(),
    weightConsistencyScore: weightConsistencyScore.roundToDouble(),
    waterScore: waterScore.roundToDouble(),
    overallHealthScore: overall,
  );
});

/// Auto-syncs the computed health score and stats into DashboardStatsModel.
final autoSyncDashboardStatsProvider = Provider<void>((ref) {
  final healthScore = ref.watch(healthScoreProvider);
  final user = ref.watch(authControllerProvider).value;
  final metrics = ref.watch(weightMetricsProvider);
  final fasting = ref.watch(fastingMetricsProvider);

  if (user == null) return;

  final currentWeight = metrics.currentWeight ?? user.currentWeightKg ?? 0.0;
  final stats = DashboardStatsModel(
    currentWeight: currentWeight,
    weightLost: metrics.weightLost ?? 0.0,
    goalProgress: metrics.goalProgressPercentage ?? 0.0,
    latestBMI: metrics.bmi ?? 0.0,
    latestTDEE: metrics.tdee ?? 0.0,
    currentFastingStreak: fasting.currentStreakDays,
    longestFastingStreak: fasting.currentStreakDays,
    healthScore: healthScore,
    lastUpdated: DateTime.now(),
  );

  ref.read(dashboardStatsRepositoryProvider).updateStats(user.uid, stats);
});
