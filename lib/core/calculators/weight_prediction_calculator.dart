import 'dart:math';

/// Weight prediction calculator using linear regression.
abstract final class WeightPredictionCalculator {
  /// Predicts weight at a future date based on historical data.
  ///
  /// Uses simple linear regression on the weight entries.
  /// [entries] is a list of (dayIndex, weight) pairs.
  /// [daysAhead] is how many days into the future to predict.
  static double predict({
    required List<({int day, double weight})> entries,
    required int daysAhead,
  }) {
    if (entries.isEmpty) return 0;
    if (entries.length == 1) return entries.first.weight;

    final n = entries.length;
    var sumX = 0.0;
    var sumY = 0.0;
    var sumXY = 0.0;
    var sumX2 = 0.0;

    for (final entry in entries) {
      sumX += entry.day;
      sumY += entry.weight;
      sumXY += entry.day * entry.weight;
      sumX2 += entry.day * entry.day;
    }

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return entries.last.weight;

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final intercept = (sumY - slope * sumX) / n;

    final lastDay = entries.last.day;
    return intercept + slope * (lastDay + daysAhead);
  }

  /// Calculates the moving average for trend smoothing.
  ///
  /// [window] is the number of entries to average (default: 7 for weekly).
  static List<double> movingAverage({
    required List<double> weights,
    int window = 7,
  }) {
    if (weights.length < window) {
      final avg = weights.reduce((a, b) => a + b) / weights.length;
      return List.filled(weights.length, avg);
    }

    final result = <double>[];
    for (var i = 0; i < weights.length; i++) {
      final start = max(0, i - window + 1);
      final sublist = weights.sublist(start, i + 1);
      result.add(sublist.reduce((a, b) => a + b) / sublist.length);
    }
    return result;
  }

  /// Calculates the rate of weight change (kg/week).
  static double weeklyRate({
    required List<({int day, double weight})> entries,
  }) {
    if (entries.length < 2) return 0;

    final first = entries.first;
    final last = entries.last;
    final days = last.day - first.day;
    if (days == 0) return 0;

    final totalChange = last.weight - first.weight;
    return (totalChange / days) * 7;
  }

  /// Detects if the user is on a weight loss plateau.
  ///
  /// A plateau is defined as < 0.2kg change over the last [days] period.
  static bool isOnPlateau({
    required List<({int day, double weight})> entries,
    int days = 14,
  }) {
    if (entries.length < 2) return false;

    final recentEntries = entries
        .where((e) => e.day >= entries.last.day - days)
        .toList();

    if (recentEntries.length < 2) return false;

    final weights = recentEntries.map((e) => e.weight).toList();
    final maxWeight = weights.reduce(max);
    final minWeight = weights.reduce(min);

    return (maxWeight - minWeight).abs() < 0.2;
  }
}
