import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_nutrition_summary_model.freezed.dart';
part 'daily_nutrition_summary_model.g.dart';

@freezed
class DailyNutritionSummaryModel with _$DailyNutritionSummaryModel {
  const factory DailyNutritionSummaryModel({
    required String userId,
    required String dateString, // e.g., '2026-06-11'
    required double totalCalories,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    double? totalFiber,
    double? totalSugar,
    double? totalSodium,
    required int waterIntakeMl,
    @Default(0) int mealCount,
    double? averageCaloriesPerMeal,

    // Goals / Remaining calculations stored for quick dashboard access
    required double targetCalories,
    double? targetProtein,
    double? targetCarbs,
    double? targetFat,
    int? waterGoalMl,

    // These could be computed or stored:
    double? remainingCalories,
    double? remainingProtein,
    double? remainingCarbs,
    double? remainingFat,

    // AI / lightweight signals
    @Default(false) bool proteinTargetMet,
    @Default(false) bool calorieTargetExceeded,
    @Default(false) bool calorieTargetMet,
    @Default(false) bool waterGoalMet,
    @Default(false) bool fiberGoalMet,
    
    required DateTime lastUpdated,
  }) = _DailyNutritionSummaryModel;

  factory DailyNutritionSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$DailyNutritionSummaryModelFromJson(json);
}
