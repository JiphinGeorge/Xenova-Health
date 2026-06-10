/// Unit system preference for weight and height.
enum UnitSystem {
  metric(label: 'Metric', weightUnit: 'kg', heightUnit: 'cm'),
  imperial(label: 'Imperial', weightUnit: 'lbs', heightUnit: 'in');

  const UnitSystem({
    required this.label,
    required this.weightUnit,
    required this.heightUnit,
  });

  final String label;
  final String weightUnit;
  final String heightUnit;
}

/// Theme mode preference.
enum AppThemeMode {
  system(label: 'System'),
  light(label: 'Light'),
  dark(label: 'Dark');

  const AppThemeMode({required this.label});

  final String label;
}

/// Goal types for tracking.
enum GoalType {
  weight(label: 'Weight Goal'),
  waist(label: 'Waist Goal'),
  fasting(label: 'Fasting Goal'),
  calories(label: 'Calorie Goal'),
  steps(label: 'Steps Goal');

  const GoalType({required this.label});

  final String label;
}

/// Sync status for offline-first operations.
enum SyncStatus { synced, pending, failed, conflict }

/// Subscription tier.
enum SubscriptionTier {
  free(label: 'Free'),
  premium(label: 'Premium');

  const SubscriptionTier({required this.label});

  final String label;
}
