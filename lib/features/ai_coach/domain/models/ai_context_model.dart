import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_context_model.freezed.dart';
part 'ai_context_model.g.dart';

@freezed
class AIContextModel with _$AIContextModel {
  const factory AIContextModel({
    required String contextVersion,
    required DateTime generatedAt,
    
    // User Metrics (No PII)
    required int? ageRange, // e.g., 25, 30 (nearest 5) or calculated age
    required String? gender,
    required double? heightCm,
    required String? goalType,
    
    // Analytics
    required double healthScore,
    required double consistencyScore,
    required double weightTrend, // Latest change
    required Map<String, dynamic> nutritionMetrics,
    required Map<String, dynamic> fastingMetrics,
    required double goalProgress,

    // Recent Signals (Last Day)
    required bool proteinGoalMet,
    required bool waterGoalMet,
    required bool calorieTargetMet,
  }) = _AIContextModel;

  factory AIContextModel.fromJson(Map<String, dynamic> json) =>
      _$AIContextModelFromJson(json);
}
