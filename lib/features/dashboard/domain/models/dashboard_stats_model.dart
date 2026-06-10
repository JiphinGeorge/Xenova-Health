import 'package:freezed_annotation/freezed_annotation.dart';
import 'ai_usage_stats_model.dart';
import 'health_score_model.dart';

part 'dashboard_stats_model.freezed.dart';
part 'dashboard_stats_model.g.dart';

/// Lightweight document to cache dashboard statistics and prevent expensive
/// recalculations on every load.
@freezed
class DashboardStatsModel with _$DashboardStatsModel {
  const factory DashboardStatsModel({
    required double currentWeight,
    required double weightLost,
    required double goalProgress,
    required double latestBMI,
    required double latestTDEE,
    required DateTime lastUpdated,
    int? currentFastingStreak,
    int? longestFastingStreak,
    DateTime? lastFastCompletedAt,

    // Health Score
    HealthScoreModel? healthScore,
    
    // AI Stats
    AiUsageStats? aiStats,
  }) = _DashboardStatsModel;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsModelFromJson(json);
}
