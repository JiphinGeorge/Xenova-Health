import 'package:csv/csv.dart';

import '../../../fasting/domain/models/fasting_session_model.dart';
import '../../../nutrition/domain/models/daily_nutrition_summary_model.dart';
import '../../../nutrition/domain/models/meal_log_model.dart';
import '../../../weight/domain/models/weight_entry_model.dart';

class CsvGenerator {
  /// Generates a CSV for Weight History.
  String generateWeightCsv(List<WeightEntryModel> entries) {
    List<List<dynamic>> rows = [
      ['Date', 'Weight (kg)', 'Note', 'Source'],
    ];

    for (final entry in entries) {
      rows.add([
        entry.date.toIso8601String().split('T').first,
        entry.weight,
        entry.note ?? '',
        entry.source,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generates a CSV for Nutrition History.
  String generateNutritionCsv(List<DailyNutritionSummaryModel> summaries) {
    List<List<dynamic>> rows = [
      [
        'Date',
        'Total Calories (kcal)',
        'Total Protein (g)',
        'Total Carbs (g)',
        'Total Fat (g)',
        'Water Intake (ml)',
      ],
    ];

    for (final summary in summaries) {
      rows.add([
        summary.dateString.split('T').first,
        summary.totalCalories,
        summary.totalProtein,
        summary.totalCarbs,
        summary.totalFat,
        summary.waterIntakeMl,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generates a CSV for individual Meal Logs.
  String generateMealLogsCsv(List<MealLogModel> meals) {
    List<List<dynamic>> rows = [
      [
        'Date',
        'Meal Type',
        'Food Items',
        'Calories (kcal)',
        'Protein (g)',
        'Carbs (g)',
        'Fat (g)',
        'Notes',
      ],
    ];

    for (final meal in meals) {
      final itemsDescription = meal.mealItems
          .map((i) => '${i.foodName} (${i.servingConsumedGrams.toStringAsFixed(0)}g)')
          .join('; ');
      rows.add([
        meal.date.toIso8601String().split('T').first,
        meal.mealType,
        itemsDescription.isNotEmpty ? itemsDescription : (meal.mealName ?? 'Meal'),
        meal.totalCalories,
        meal.totalProtein,
        meal.totalCarbs,
        meal.totalFat,
        meal.note ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generates a CSV for Fasting History.
  String generateFastingCsv(List<FastingSessionModel> sessions) {
    List<List<dynamic>> rows = [
      ['Start Time', 'End Time', 'Target Duration (hrs)', 'Completed'],
    ];

    for (final session in sessions) {
      rows.add([
        session.startTime.toIso8601String(),
        session.endTime?.toIso8601String() ?? 'Active',
        session.targetDurationHours,
        session.endTime != null ? 'Yes' : 'No',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
}
