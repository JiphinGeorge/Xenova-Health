import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/daily_nutrition_repository.dart';
import '../../data/repositories/meal_log_repository.dart';
import '../../domain/models/daily_nutrition_summary_model.dart';
import '../../domain/models/meal_log_model.dart';

/// Central controller orchestrating Nutrition Operations.
class NutritionController extends StateNotifier<AsyncValue<void>> {
  NutritionController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  /// Adds a meal log and transactionally updates the daily summary
  Future<void> logMeal(MealLogModel mealLog) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      // 1. Add the meal log
      await _ref.read(mealLogRepositoryProvider).addMealLog(mealLog);

      // 2. Transactionally update macros in the daily summary
      final dateString =
          '${mealLog.date.year}-${mealLog.date.month.toString().padLeft(2, '0')}-${mealLog.date.day.toString().padLeft(2, '0')}';

      await _ref
          .read(dailyNutritionRepositoryProvider)
          .addMacros(
            user.uid,
            dateString,
            calories: mealLog.totalCalories,
            protein: mealLog.totalProtein,
            carbs: mealLog.totalCarbs,
            fat: mealLog.totalFat,
            fiber: mealLog.totalFiber,
            sugar: mealLog.totalSugar,
            sodium: mealLog.totalSodium,
          );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Deletes a meal log and transactionally deducts the macros from the daily summary
  Future<void> deleteMealLog(MealLogModel mealLog) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      // 1. Delete the meal log
      await _ref
          .read(mealLogRepositoryProvider)
          .deleteMealLog(user.uid, mealLog.id);

      // 2. Transactionally deduct macros from the daily summary
      final dateString =
          '${mealLog.date.year}-${mealLog.date.month.toString().padLeft(2, '0')}-${mealLog.date.day.toString().padLeft(2, '0')}';

      await _ref
          .read(dailyNutritionRepositoryProvider)
          .removeMacros(
            user.uid,
            dateString,
            calories: mealLog.totalCalories,
            protein: mealLog.totalProtein,
            carbs: mealLog.totalCarbs,
            fat: mealLog.totalFat,
            fiber: mealLog.totalFiber,
            sugar: mealLog.totalSugar,
            sodium: mealLog.totalSodium,
          );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Updates daily water intake by adding or subtracting the amount
  Future<void> logWater(DateTime date, int amountMl) async {
    try {
      final user = _ref.read(authControllerProvider).value;
      if (user == null) return;

      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await _ref
          .read(dailyNutritionRepositoryProvider)
          .updateWaterIntake(user.uid, dateString, amountMl);
    } catch (e) {
      // Silently fail or track analytics
    }
  }
}

final nutritionControllerProvider =
    StateNotifierProvider<NutritionController, AsyncValue<void>>((ref) {
      return NutritionController(ref);
    });

/// Provider for watching the selected date's daily summary.
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dailyNutritionSummaryStreamProvider =
    StreamProvider<DailyNutritionSummaryModel?>((ref) {
      final user = ref.watch(authControllerProvider).value;
      if (user == null) return const Stream.empty();

      final selectedDate = ref.watch(selectedDateProvider);
      final dateString =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      return ref
          .watch(dailyNutritionRepositoryProvider)
          .watchDailySummary(user.uid, dateString);
    });

/// Provider for watching meal logs on the selected date.
final dailyMealLogsStreamProvider = StreamProvider<List<MealLogModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const Stream.empty();

  final selectedDate = ref.watch(selectedDateProvider);

  return ref
      .watch(mealLogRepositoryProvider)
      .watchMealLogsForDate(user.uid, selectedDate);
});
