/// Defines the user's nutritional preferences or dietary restrictions.
enum DietType {
  none('No Preference'),
  vegetarian('Vegetarian'),
  vegan('Vegan'),
  eggetarian('Eggetarian'),
  highProtein('High Protein');

  const DietType(this.label);

  /// The human-readable label for the diet type.
  final String label;
}
