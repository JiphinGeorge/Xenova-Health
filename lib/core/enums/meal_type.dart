/// Meal type categories for daily meal logging.
enum MealType {
  breakfast(label: 'Breakfast', icon: '🌅', sortOrder: 0),
  lunch(label: 'Lunch', icon: '☀️', sortOrder: 1),
  dinner(label: 'Dinner', icon: '🌙', sortOrder: 2),
  snacks(label: 'Snacks', icon: '🍎', sortOrder: 3);

  const MealType({
    required this.label,
    required this.icon,
    required this.sortOrder,
  });

  final String label;
  final String icon;
  final int sortOrder;
}
