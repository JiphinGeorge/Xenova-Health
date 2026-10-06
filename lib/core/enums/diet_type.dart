/// Defines the user's nutritional preferences or dietary restrictions.
enum DietType {
  none(
    'No Preference',
    'Standard diet with no specific restrictions',
  ),
  omnivore(
    'Omnivore',
    'Everything — meat, fish, dairy, eggs, plants',
  ),
  pescatarian(
    'Pescatarian',
    'No meat/poultry, but fish, dairy, and eggs are fine',
  ),
  flexitarian(
    'Flexitarian',
    'Mostly plant-based, with occasional meat',
  ),
  vegetarian(
    'Vegetarian',
    'No meat, poultry, or fish; includes dairy and eggs',
  ),
  vegan(
    'Vegan',
    'Strictly plant-based; no meat, fish, dairy, or eggs',
  ),
  eggetarian(
    'Eggetarian',
    'Vegetarian with eggs included, no meat or poultry',
  ),
  highProtein(
    'High Protein',
    'Prioritizes high-protein meals across all food sources',
  );

  const DietType(this.label, this.description);

  /// The human-readable label for the diet type.
  final String label;

  /// What foods and items are included in this diet type.
  final String description;
}
