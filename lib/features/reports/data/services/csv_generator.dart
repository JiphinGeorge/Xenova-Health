import 'package:csv/csv.dart';

import '../../../dashboard/domain/models/dashboard_stats_model.dart';
import '../../../fasting/domain/models/fasting_session_model.dart';
import '../../../nutrition/domain/models/daily_nutrition_summary_model.dart';
import '../../../weight/domain/models/weight_entry_model.dart';

class CsvGenerator {
  /// Generates a CSV for Weight History.
  String generateWeightCsv(List<WeightEntryModel> entries) {
    List<List<dynamic>> rows = [
      ['Date', 'Weight (kg)', 'Note', 'Source'],
    ];

    for (final entry in entries) {
      rows.add([
        entry.date.toIso8601String(),
        entry.weight,
        entry.note ?? '',
        entry.source ?? 'manual',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generates a CSV for Nutrition History.
  String generateNutritionCsv(List<DailyNutritionSummaryModel> summaries) {
    List<List<dynamic>> rows = [
      ['Date', 'Total Calories', 'Total Protein (g)', 'Total Carbs (g)', 'Total Fat (g)', 'Water Intake (ml)'],
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
