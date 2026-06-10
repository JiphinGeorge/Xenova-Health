import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/food_item_model.dart';
import '../../domain/models/meal_log_model.dart';
import 'nutrition_controller.dart';

/// State of the currently built meal.
class MealBuilderState {
  final List<MealItemModel> items;

  MealBuilderState({this.items = const []});

  MealBuilderState copyWith({List<MealItemModel>? items}) {
    return MealBuilderState(items: items ?? this.items);
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
    state = MealBuilderState();
  }

  /// Saves the built meal to Firestore via NutritionController.
  Future<void> saveMeal({
    required String mealType,
    String? mealName,
    String? note,
  }) async {
    if (state.items.isEmpty) return;

    final user = _ref.read(authControllerProvider).value;
    if (user == null) throw Exception('User not logged in');

    final date = _ref.read(selectedDateProvider);

    final mealLog = MealLogModel(
      id: const Uuid().v4(),
      userId: user.uid,
      date: date,
      mealType: mealType,
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
}

final mealLoggingProvider =
    StateNotifierProvider<MealLoggingController, MealBuilderState>((ref) {
      return MealLoggingController(ref);
    });
