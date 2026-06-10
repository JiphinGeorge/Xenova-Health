/// Numeric extensions for Xenova Health.
extension NumExtensions on num {
  /// Formats as weight string with unit (e.g., "72.5 kg").
  String toWeightString({String unit = 'kg', int decimals = 1}) =>
      '${toStringAsFixed(decimals)} $unit';

  /// Formats as calorie string (e.g., "1,850 kcal").
  String toCalorieString() {
    final formatted = toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '$formatted kcal';
  }

  /// Formats as macro nutrient string (e.g., "45.2g").
  String toMacroString({String unit = 'g', int decimals = 1}) =>
      '${toStringAsFixed(decimals)}$unit';

  /// Formats as percentage string (e.g., "85%").
  String toPercentString({int decimals = 0}) => '${toStringAsFixed(decimals)}%';

  /// Formats as measurement string (e.g., "90.5 cm").
  String toMeasurementString({String unit = 'cm', int decimals = 1}) =>
      '${toStringAsFixed(decimals)} $unit';

  /// Converts kg to lbs.
  double get kgToLbs => this * 2.20462;

  /// Converts lbs to kg.
  double get lbsToKg => this / 2.20462;

  /// Converts cm to inches.
  double get cmToInches => this / 2.54;

  /// Converts inches to cm.
  double get inchesToCm => this * 2.54;

  /// Converts ml to liters.
  double get mlToLiters => this / 1000;

  /// Clamps value between 0 and 1 for progress indicators.
  double get clampProgress => toDouble().clamp(0.0, 1.0);
}

/// Integer-specific extensions.
extension IntExtensions on int {
  /// Formats as duration string from minutes (e.g., "2h 30m").
  String get toDurationString {
    if (this < 60) return '${this}m';
    final hours = this ~/ 60;
    final mins = this % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  /// Formats as compact number (e.g., "1.2k", "2.5M").
  String get toCompactString {
    if (this < 1000) return toString();
    if (this < 1000000) return '${(this / 1000).toStringAsFixed(1)}k';
    return '${(this / 1000000).toStringAsFixed(1)}M';
  }
}
