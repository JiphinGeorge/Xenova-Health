/// Calorie deficit and weight loss projection calculator.
abstract final class CalorieDeficitCalculator {
  /// 1 kg of body fat ≈ 7,700 kcal.
  static const double kcalPerKgFat = 7700;

  /// 1 lb of body fat ≈ 3,500 kcal.
  static const double kcalPerLbFat = 3500;

  /// Calculates daily calorie deficit.
  ///
  /// Returns positive value for deficit, negative for surplus.
  static double dailyDeficit({
    required double tdee,
    required double caloriesConsumed,
  }) {
    return tdee - caloriesConsumed;
  }

  /// Calculates expected weekly weight loss in kg.
  static double weeklyWeightLossKg({required double dailyDeficit}) {
    if (dailyDeficit <= 0) return 0;
    return (dailyDeficit * 7) / kcalPerKgFat;
  }

  /// Calculates recommended daily calorie intake for a target weekly loss.
  ///
  /// [targetWeeklyLossKg] is the desired weekly weight loss in kg.
  static double recommendedDailyIntake({
    required double tdee,
    required double targetWeeklyLossKg,
  }) {
    final dailyDeficitNeeded = (targetWeeklyLossKg * kcalPerKgFat) / 7;
    final intake = tdee - dailyDeficitNeeded;
    // Never recommend below 1200 kcal for women or 1500 for men (safety floor)
    return intake.clamp(1200, tdee);
  }

  /// Estimates days to reach target weight.
  static int daysToTarget({
    required double currentWeightKg,
    required double targetWeightKg,
    required double dailyDeficit,
  }) {
    if (dailyDeficit <= 0) return -1; // Cannot reach target with surplus
    final weightToLose = currentWeightKg - targetWeightKg;
    if (weightToLose <= 0) return 0; // Already at or below target
    final totalDeficitNeeded = weightToLose * kcalPerKgFat;
    return (totalDeficitNeeded / dailyDeficit).ceil();
  }
}
