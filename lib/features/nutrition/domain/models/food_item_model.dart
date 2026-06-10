import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_item_model.freezed.dart';
part 'food_item_model.g.dart';

@freezed
class FoodItemModel with _$FoodItemModel {
  const factory FoodItemModel({
    required String id,
    required String name,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required double servingSizeGrams,
    String? brandName,
    String? barcode,
    double? fiber,
    double? sugar,
    double? sodium,
    @Default(false) bool isVerified,
    @Default(false) bool isFavorite,
    @Default(false) bool isCustom,
    String? createdByUserId, // If custom food
    DateTime? createdAt,
    DateTime? recentlyUsedAt,
    @Default([]) List<String> searchKeywords,
  }) = _FoodItemModel;

  factory FoodItemModel.fromJson(Map<String, dynamic> json) =>
      _$FoodItemModelFromJson(json);
}
