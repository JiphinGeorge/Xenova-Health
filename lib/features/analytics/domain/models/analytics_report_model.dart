import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_report_model.freezed.dart';
part 'analytics_report_model.g.dart';

@freezed
class AnalyticsReportModel with _$AnalyticsReportModel {
  const factory AnalyticsReportModel({
    required String id, // e.g., weekly_2026_24
    required String userId,
    required String reportType, // e.g., 'weekly', 'monthly', 'quarterly'
    required String dataRange, // e.g., '2026-06-01 to 2026-06-07'
    required DateTime startDate,
    required DateTime endDate,
    
    // Core Metrics
    required double weightChange,
    required double averageWeeklyWeightChange,
    required double averageDailyCalories,
    required double averageDailyProtein,
    required int averageDailyWater,
    required double averageFastDuration,
    required double fastCompletionRate,
    
    // Scores
    required double consistencyScore,
    required double goalProgressPercentage,
    
    // Trends (e.g., last 7 days of data points)
    @Default([]) List<double> weightTrendArray,
    @Default([]) List<double> calorieTrendArray,
    @Default([]) List<double> proteinTrendArray,
    @Default([]) List<double> fastingTrendArray,
    
    required DateTime generatedAt,
  }) = _AnalyticsReportModel;

  factory AnalyticsReportModel.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsReportModelFromJson(json);
}
