import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/food_item_model.dart';
import '../../domain/models/meal_log_model.dart';
import 'nutrition_controller.dart';

/// State of the currently built meal.
class MealBuilderState {
  final List<MealItemModel> items;
  final String mealType;

  MealBuilderState({
    this.items = const [],
    this.mealType = 'Breakfast',
  });

  MealBuilderState copyWith({
    List<MealItemModel>? items,
    String? mealType,
  }) {
    return MealBuilderState(
      items: items ?? this.items,
      mealType: mealType ?? this.mealType,
    );
  }

  double get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
  double get totalProtein => items.fold(0, (sum, item) => sum + item.protein);
  double get totalCarbs => items.fold(0, (sum, item) => sum + item.carbs);
  double get totalFat => items.fold(0, (sum, item) => sum + item.fat);
  double get totalFiber =>
      items.fold(0, (sum, item) => sum + (item.fiber ?? 0.0));
  double get totalSugar =>
      items.fold(0, (sum, item) => sum + (item.sugar ?? 0.0));
  double get totalSodium =>
      items.fold(0, (sum, item) => sum + (item.sodium ?? 0.0));
}

class MealLoggingController extends StateNotifier<MealBuilderState> {
  MealLoggingController(this._ref) : super(MealBuilderState());

  final Ref _ref;

  /// Sets the meal category (Breakfast, Lunch, Dinner, Snack)
  void setMealType(String mealType) {
    state = state.copyWith(mealType: mealType);
  }

  /// Adds a food item to the current meal being built.
  void addFood(FoodItemModel food, double servingConsumedGrams) {
    // Calculate the ratio based on the base serving size.
    final ratio = servingConsumedGrams / food.servingSizeGrams;

    final mealItem = MealItemModel(
      foodId: food.id,
      foodName: food.name,
      calories: food.calories * ratio,
      protein: food.protein * ratio,
      carbs: food.carbs * ratio,
      fat: food.fat * ratio,
      fiber: food.fiber != null ? food.fiber! * ratio : null,
      sugar: food.sugar != null ? food.sugar! * ratio : null,
      sodium: food.sodium != null ? food.sodium! * ratio : null,
      servingConsumedGrams: servingConsumedGrams,
    );

    state = state.copyWith(items: [...state.items, mealItem]);
  }

  /// Removes an item at a specific index from the meal.
  void removeFood(int index) {
    final newItems = List<MealItemModel>.from(state.items);
    if (index >= 0 && index < newItems.length) {
      newItems.removeAt(index);
      state = state.copyWith(items: newItems);
    }
  }

  /// Clears the current meal builder.
  void clearMeal() {
    state = MealBuilderState(mealType: state.mealType);
  }

  /// Saves the built meal via NutritionController.
  Future<void> saveMeal({
    String? mealType,
    String? mealName,
    String? note,
  }) async {
    if (state.items.isEmpty) return;

    final user = _ref.read(authControllerProvider).value;
    final userId = user?.uid ?? 'guest_user';

    final date = _ref.read(selectedDateProvider);
    final finalMealType = mealType ?? state.mealType;

    final mealLog = MealLogModel(
      id: const Uuid().v4(),
      userId: userId,
      date: date,
      mealType: finalMealType,
      mealName: mealName,
      note: note,
      mealItems: state.items,
      totalCalories: state.totalCalories,
      totalProtein: state.totalProtein,
      totalCarbs: state.totalCarbs,
      totalFat: state.totalFat,
      totalFiber: state.totalFiber,
      totalSugar: state.totalSugar,
      totalSodium: state.totalSodium,
      createdAt: DateTime.now(),
    );

    await _ref.read(nutritionControllerProvider.notifier).logMeal(mealLog);

    clearMeal(); // Reset builder after saving
  }

  /// Quick logs a single food item immediately without needing multi-step review.
  Future<void> quickLogSingleFood({
    required FoodItemModel food,
    required double servingConsumedGrams,
    String? mealType,
  }) async {
    final ratio = food.servingSizeGrams > 0
        ? servingConsumedGrams / food.servingSizeGrams
        : 1.0;
    final mealItem = MealItemModel(
      foodId: food.id,
      foodName: food.name,
      calories: food.calories * ratio,
      protein: food.protein * ratio,
      carbs: food.carbs * ratio,
      fat: food.fat * ratio,
      fiber: food.fiber != null ? food.fiber! * ratio : null,
      sugar: food.sugar != null ? food.sugar! * ratio : null,
      sodium: food.sodium != null ? food.sodium! * ratio : null,
      servingConsumedGrams: servingConsumedGrams,
    );

    final user = _ref.read(authControllerProvider).value;
    final userId = user?.uid ?? 'guest_user';
    final date = _ref.read(selectedDateProvider);
    final finalMealType = (mealType != null && mealType.trim().isNotEmpty)
        ? mealType.trim()
        : state.mealType;

    final mealLog = MealLogModel(
      id: const Uuid().v4(),
      userId: userId,
      date: date,
      mealType: finalMealType,
      mealName: food.name,
      mealItems: [mealItem],
      totalCalories: mealItem.calories,
      totalProtein: mealItem.protein,
      totalCarbs: mealItem.carbs,
      totalFat: mealItem.fat,
      totalFiber: mealItem.fiber,
      totalSugar: mealItem.sugar,
      totalSodium: mealItem.sodium,
      createdAt: DateTime.now(),
    );

    await _ref.read(nutritionControllerProvider.notifier).logMeal(mealLog);
  }
}

final mealLoggingProvider =
    StateNotifierProvider<MealLoggingController, MealBuilderState>((ref) {
      return MealLoggingController(ref);
    });
