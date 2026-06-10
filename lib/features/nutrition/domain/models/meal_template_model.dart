import 'package:freezed_annotation/freezed_annotation.dart';

import 'meal_log_model.dart';

part 'meal_template_model.freezed.dart';
part 'meal_template_model.g.dart';

@freezed
class MealTemplateModel with _$MealTemplateModel {
  const factory MealTemplateModel({
    required String id,
    required String userId,
    required String templateName, // e.g., 'High Protein Breakfast'
    required List<MealItemModel> mealItems,
    required double totalCalories,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    required DateTime createdAt,
  }) = _MealTemplateModel;

  factory MealTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$MealTemplateModelFromJson(json);
}
