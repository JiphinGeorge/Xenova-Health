import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_snapshot_model.freezed.dart';
part 'analytics_snapshot_model.g.dart';

/// Lightweight summary model designed specifically for the AI Coach to consume.
@freezed
class AnalyticsSnapshot with _$AnalyticsSnapshot {
  const factory AnalyticsSnapshot({
    required Map<String, dynamic> weightMetrics,
    required Map<String, dynamic> nutritionMetrics,
    required Map<String, dynamic> fastingMetrics,
    required Map<String, dynamic> goalMetrics,
    required Map<String, dynamic> consistencyMetrics,
    @Default([]) List<String> recommendations,
    @Default('1.0') String snapshotVersion,
    required DateTime generatedAt,
    required DateTime lastUpdated,
  }) = _AnalyticsSnapshot;

  factory AnalyticsSnapshot.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsSnapshotFromJson(json);
}
