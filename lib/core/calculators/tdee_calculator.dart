import '../enums/activity_level.dart';

/// TDEE (Total Daily Energy Expenditure) calculator.
///
/// TDEE = BMR × Activity Multiplier
abstract final class TdeeCalculator {
  /// Calculates TDEE in kcal/day.
  static double calculate({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    if (bmr <= 0) return 0;
    return bmr * activityLevel.multiplier;
  }
}
