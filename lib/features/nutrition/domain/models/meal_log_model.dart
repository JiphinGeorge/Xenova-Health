import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_log_model.freezed.dart';
part 'meal_log_model.g.dart';

@freezed
class MealItemModel with _$MealItemModel {
  const factory MealItemModel({
    required String foodId,
    required String foodName,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required double servingConsumedGrams,
    double? fiber,
    double? sugar,
    double? sodium,
  }) = _MealItemModel;

  factory MealItemModel.fromJson(Map<String, dynamic> json) =>
      _$MealItemModelFromJson(json);
}

@freezed
class MealLogModel with _$MealLogModel {
  const factory MealLogModel({
    required String id,
    required String userId,
    required DateTime date,
    required String
    mealType, // Breakfast, Lunch, Dinner, Snack, Pre-Workout, Post-Workout
    String? mealName, // Optional custom name
    String? note,
    required List<MealItemModel> mealItems,
    required double totalCalories,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    double? totalFiber,
    double? totalSugar,
    double? totalSodium,
    required DateTime createdAt,
  }) = _MealLogModel;

  factory MealLogModel.fromJson(Map<String, dynamic> json) =>
      _$MealLogModelFromJson(json);
}
