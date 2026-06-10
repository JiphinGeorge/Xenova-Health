import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_usage_stats_model.freezed.dart';
part 'ai_usage_stats_model.g.dart';

@freezed
class AiUsageStats with _$AiUsageStats {
  const factory AiUsageStats({
    @Default(0) int totalRequests,
    @Default(0) int successfulRequests,
    @Default(0) int failedRequests,
    DateTime? lastRequest,
    
    // Conversation Analytics
    @Default(0) int totalChats,
    @Default(0.0) double averageResponseLength,
    String? mostUsedPromptType,
  }) = _AiUsageStats;

  factory AiUsageStats.fromJson(Map<String, dynamic> json) =>
      _$AiUsageStatsFromJson(json);
}
