/// Defines the user's primary goal for using the application.
enum PrimaryGoal {
  loseWeight('Lose Weight'),
  maintainWeight('Maintain Weight'),
  gainWeight('Gain Weight'),
  improveFitness('Improve Fitness'),
  buildHealthyHabits('Build Healthy Habits');

  const PrimaryGoal(this.label);

  /// The human-readable label for the goal.
  final String label;
}
