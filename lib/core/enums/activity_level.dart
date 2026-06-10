/// User activity level for TDEE calculation.
enum ActivityLevel {
  /// Little or no exercise, desk job.
  sedentary(
    label: 'Sedentary',
    description: 'Little or no exercise',
    multiplier: 1.2,
  ),

  /// Light exercise 1-3 days/week.
  lightlyActive(
    label: 'Lightly Active',
    description: 'Light exercise 1-3 days/week',
    multiplier: 1.375,
  ),

  /// Moderate exercise 3-5 days/week.
  moderatelyActive(
    label: 'Moderately Active',
    description: 'Moderate exercise 3-5 days/week',
    multiplier: 1.55,
  ),

  /// Hard exercise 6-7 days/week.
  veryActive(
    label: 'Very Active',
    description: 'Hard exercise 6-7 days/week',
    multiplier: 1.725,
  ),

  /// Very hard exercise & physical job.
  extraActive(
    label: 'Extra Active',
    description: 'Very hard exercise & physical job',
    multiplier: 1.9,
  );

  const ActivityLevel({
    required this.label,
    required this.description,
    required this.multiplier,
  });

  final String label;
  final String description;

  /// Harris-Benedict multiplier for TDEE calculation.
  final double multiplier;
}
