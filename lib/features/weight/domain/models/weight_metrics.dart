/// Computed metrics for the user's weight tracking.
class WeightMetrics {
  const WeightMetrics({
    this.currentWeight,
    this.startWeight,
    this.targetWeight,
    this.weightLost,
    this.changeSinceLast,
    this.weeklyAverage,
    this.monthlyAverage,
    this.bmi,
    this.bmr,
    this.tdee,
    this.goalProgressPercentage,
    this.predictedGoalDate,
    this.trendInsight,
  });

  final double? currentWeight;
  final double? startWeight;
  final double? targetWeight;
  final double? weightLost;
  final double? changeSinceLast;
  final double? weeklyAverage;
  final double? monthlyAverage;
  final double? bmi;
  final double? bmr;
  final double? tdee;
  final double? goalProgressPercentage;
  final DateTime? predictedGoalDate;
  final String? trendInsight;
}
