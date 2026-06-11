import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/data/repositories/dashboard_stats_repository.dart';
import '../../../fasting/data/repositories/fasting_repository.dart';
import '../../../nutrition/data/repositories/daily_nutrition_repository.dart';
import '../../../weight/data/repositories/weight_repository.dart';
import '../../domain/models/analytics_report_model.dart';
import '../../domain/models/analytics_snapshot_model.dart';

/// Client-side aggregation service that builds AnalyticsReports
class AnalyticsAggregationService {
  AnalyticsAggregationService(
    this._weightRepo,
    this._nutritionRepo,
    this._fastingRepo,
    this._dashboardRepo,
  );

  final WeightRepository _weightRepo;
  final DailyNutritionRepository _nutritionRepo;
  final FastingRepository _fastingRepo;
  final DashboardStatsRepository _dashboardRepo;

  /// Generates a time-bound analytics report.
  Future<AnalyticsReportModel> generateReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required String reportId,
  }) async {
    // 1. Fetch all raw logs
    final weightLogs = await _weightRepo.getWeightEntriesForRange(userId, startDate, endDate);
    final nutritionLogs = await _nutritionRepo.getNutritionSummaryForRange(userId, startDate, endDate);
    final fastingLogs = await _fastingRepo.getFastingSessionsForRange(userId, startDate, endDate);

    // 2. Compute Analytics
    
    // Weight Trends
    double startWeight = weightLogs.isNotEmpty ? weightLogs.last.weight : 0.0;
    double endWeight = weightLogs.isNotEmpty ? weightLogs.first.weight : 0.0;
    double weightChange = endWeight - startWeight;
    
    // Nutrition Trends
    double totalCals = 0;
    double totalProtein = 0;
    int totalWater = 0;
    int daysLoggedNutrition = nutritionLogs.length;

    for (final log in nutritionLogs) {
      totalCals += log.totalCalories;
      totalProtein += log.totalProtein;
      totalWater += log.waterIntakeMl;
    }

    double avgCals = daysLoggedNutrition > 0 ? totalCals / daysLoggedNutrition : 0.0;
    double avgProtein = daysLoggedNutrition > 0 ? totalProtein / daysLoggedNutrition : 0.0;
    int avgWater = daysLoggedNutrition > 0 ? totalWater ~/ daysLoggedNutrition : 0;

    // Fasting Trends
    double totalFastDuration = 0;
    int completedFasts = 0;
    for (final fast in fastingLogs) {
      if (fast.endTime != null) {
        totalFastDuration += fast.actualDurationHours ?? 0;
        completedFasts++;
      }
    }
    double avgFastDuration = completedFasts > 0 ? totalFastDuration / completedFasts : 0.0;
    double fastCompletionRate = fastingLogs.isNotEmpty ? completedFasts / fastingLogs.length : 0.0;

    // Calculate Consistency Score (0 - 100)
    final daysDiff = endDate.difference(startDate).inDays;
    final targetDays = daysDiff == 0 ? 1 : daysDiff;
    
    double weightConsistency = (weightLogs.length / targetDays).clamp(0.0, 1.0);
    double nutritionConsistency = (daysLoggedNutrition / targetDays).clamp(0.0, 1.0);
    double fastConsistency = (fastingLogs.length / targetDays).clamp(0.0, 1.0);
    
    // Simple average for score
    double consistencyScore = ((weightConsistency + nutritionConsistency + fastConsistency) / 3.0) * 100;
    
    // Simple goal progress (mocked logic for now, could be dynamic)
    double goalProgressPct = weightChange < 0 ? 0.8 : 0.4; // Ex: Losing weight = good progress

    // Extract arrays for charts
    final weightTrendArray = weightLogs.map((l) => l.weight).toList().reversed.toList();
    final calorieTrendArray = nutritionLogs.map((l) => l.totalCalories.toDouble()).toList();
    final proteinTrendArray = nutritionLogs.map((l) => l.totalProtein.toDouble()).toList();

    final report = AnalyticsReportModel(
      id: reportId,
      userId: userId,
      reportType: reportId.split('_').first, // 'weekly', 'monthly', 'quarterly'
      dataRange: '${startDate.toIso8601String().split('T').first} to ${endDate.toIso8601String().split('T').first}',
      startDate: startDate,
      endDate: endDate,
      weightChange: weightChange,
      averageWeeklyWeightChange: weightChange / (targetDays / 7),
      averageDailyCalories: avgCals,
      averageDailyProtein: avgProtein,
      averageDailyWater: avgWater,
      averageFastDuration: avgFastDuration,
      fastCompletionRate: fastCompletionRate,
      consistencyScore: consistencyScore,
      goalProgressPercentage: goalProgressPct,
      weightTrendArray: weightTrendArray,
      calorieTrendArray: calorieTrendArray,
      proteinTrendArray: proteinTrendArray,
      generatedAt: DateTime.now(),
    );

    // 3. Save Summary Snapshot for AI Coach and Overview
    final snapshot = AnalyticsSnapshot(
      weightMetrics: {
        'weightChange': weightChange,
        'consistency': weightConsistency,
      },
      nutritionMetrics: {
        'averageCalories': avgCals,
        'averageProtein': avgProtein,
        'consistency': nutritionConsistency,
      },
      fastingMetrics: {
        'averageDuration': avgFastDuration,
        'completionRate': fastCompletionRate,
      },
      goalMetrics: {
        'progressPercentage': goalProgressPct,
      },
      consistencyMetrics: {
        'overallScore': consistencyScore,
      },
      recommendations: [
        if (weightConsistency < 0.5) "Improve weight logging consistency.",
        if (avgProtein < 100) "Increase protein intake.",
        if (avgWater < 2000) "Increase daily water intake."
      ],
      snapshotVersion: '1.0',
      generatedAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    // Normally we'd save this snapshot inside the user's dashboard stats doc
    // _dashboardRepo.updateAnalyticsSnapshot(userId, snapshot);
    // Left as future implementation detail to prevent bloated overview doc
    
    return report;
  }
}

final analyticsAggregationServiceProvider = Provider<AnalyticsAggregationService>((ref) {
  return AnalyticsAggregationService(
    ref.watch(weightRepositoryProvider),
    ref.watch(dailyNutritionRepositoryProvider),
    ref.watch(fastingRepositoryProvider),
    ref.watch(dashboardStatsRepositoryProvider),
  );
});
