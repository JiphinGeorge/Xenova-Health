import '../enums/gender.dart';

/// BMI (Body Mass Index) calculator.
///
/// Formula: weight (kg) / height (m)²
abstract final class BmiCalculator {
  /// Calculates BMI from weight in kg and height in cm.
  static double calculate({
    required double weightKg,
    required double heightCm,
  }) {
    if (weightKg <= 0 || heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Returns the BMI category label.
  static String category(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    if (bmi < 35.0) return 'Obese Class I';
    if (bmi < 40.0) return 'Obese Class II';
    return 'Obese Class III';
  }

  /// Returns a color-coded risk indicator (0.0 = healthy, 1.0 = high risk).
  static double riskFactor(double bmi) {
    if (bmi >= 18.5 && bmi < 25.0) return 0.0;
    if (bmi >= 25.0 && bmi < 30.0) return 0.3;
    if (bmi < 18.5) return 0.4;
    if (bmi >= 30.0 && bmi < 35.0) return 0.6;
    if (bmi >= 35.0 && bmi < 40.0) return 0.8;
    return 1.0;
  }
}

/// BMR (Basal Metabolic Rate) calculator.
///
/// Uses the Mifflin-St Jeor equation (most accurate for general population):
/// - Male: (10 × weight) + (6.25 × height) - (5 × age) + 5
/// - Female: (10 × weight) + (6.25 × height) - (5 × age) - 161
abstract final class BmrCalculator {
  /// Calculates BMR in kcal/day.
  static double calculate({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return 0;

    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);

    return switch (gender) {
      Gender.male => base + 5,
      Gender.female => base - 161,
      Gender.other => base - 78, // Average of male and female adjustments
    };
  }
}
