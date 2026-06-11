import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/enums/enums.dart';
import '../../../../features/dashboard/data/repositories/dashboard_stats_repository.dart';
import '../../../../features/dashboard/domain/models/dashboard_stats_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../gamification/application/services/achievement_engine_service.dart';
import '../../data/repositories/weight_repository.dart';
import '../../domain/models/weight_entry_model.dart';
import '../../domain/models/weight_metrics.dart';

/// Stream of all weight entries for the logged-in user.
final weightEntriesStreamProvider = StreamProvider<List<WeightEntryModel>>((
  ref,
) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const Stream.empty();

  final repository = ref.watch(weightRepositoryProvider);
  return repository.watchEntries(user.uid);
});

/// Provides a comprehensive snapshot of weight metrics.
final weightMetricsProvider = Provider<WeightMetrics>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final entriesAsync = ref.watch(weightEntriesStreamProvider);

  if (user == null ||
      entriesAsync.value == null ||
      entriesAsync.value!.isEmpty) {
    return const WeightMetrics();
  }

  final entries = entriesAsync.value!;
  // Sort chronologically (oldest first) to compute averages over time smoothly.
  // The stream returns descending (newest first).
  final sortedEntries = List<WeightEntryModel>.from(entries)
    ..sort((a, b) => a.date.compareTo(b.date));

  final currentWeight = sortedEntries.last.weight;
  final startWeight = sortedEntries.first.weight;
  final targetWeight = user.targetWeightKg;

  final weightLost = startWeight - currentWeight;

  double? changeSinceLast;
  if (sortedEntries.length > 1) {
    changeSinceLast =
        currentWeight - sortedEntries[sortedEntries.length - 2].weight;
  }

  // Averages
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  final monthAgo = now.subtract(const Duration(days: 30));

  final weeklyEntries = sortedEntries
      .where((e) => e.date.isAfter(weekAgo))
      .toList();
  final monthlyEntries = sortedEntries
      .where((e) => e.date.isAfter(monthAgo))
      .toList();

  final weeklyAverage = weeklyEntries.isEmpty
      ? null
      : weeklyEntries.map((e) => e.weight).reduce((a, b) => a + b) /
            weeklyEntries.length;

  final monthlyAverage = monthlyEntries.isEmpty
      ? null
      : monthlyEntries.map((e) => e.weight).reduce((a, b) => a + b) /
            monthlyEntries.length;

  // Physiological Calculations
  double? bmi;
  double? bmr;
  double? tdee;

  if (user.heightCm != null && user.age != null && user.gender != null) {
    final heightM = user.heightCm! / 100;
    bmi = currentWeight / (heightM * heightM);

    if (user.gender == Gender.male) {
      bmr =
          (10 * currentWeight) + (6.25 * user.heightCm!) - (5 * user.age!) + 5;
    } else {
      bmr =
          (10 * currentWeight) +
          (6.25 * user.heightCm!) -
          (5 * user.age!) -
          161;
    }

    tdee = bmr * (user.activityLevel?.multiplier ?? 1.2);
  }

  // Goal Progress (0.0 to 1.0)
  double? goalProgressPercentage;
  if (targetWeight != null && startWeight != targetWeight) {
    final totalToLose = (targetWeight - startWeight).abs();
    final lostSoFar = (currentWeight - startWeight).abs();
    goalProgressPercentage = (lostSoFar / totalToLose).clamp(0.0, 1.0);
  }

  // Prediction Math: 7700 kcal deficit = 1 kg loss.
  // Assuming a standard 500 kcal deficit for 'loseWeight',
  // or a 500 surplus for 'gainWeight'.
  DateTime? predictedGoalDate;
  if (targetWeight != null && user.primaryGoal != null && tdee != null) {
    double dailyDeficit = 0;
    if (user.primaryGoal == PrimaryGoal.loseWeight) dailyDeficit = 500;
    if (user.primaryGoal == PrimaryGoal.gainWeight) dailyDeficit = -500;

    if (dailyDeficit != 0) {
      final diffKg = currentWeight - targetWeight;
      // If losing weight, diff should be positive. If gaining, diff should be negative.
      final daysToGoal = (diffKg * 7700) / dailyDeficit;
      if (daysToGoal > 0) {
        predictedGoalDate = now.add(Duration(days: daysToGoal.ceil()));
      }
    }
  }

  // Trend Insights
  String? trendInsight;
  if (changeSinceLast != null) {
    if (changeSinceLast < -0.5) {
      trendInsight = 'Weight is trending downward.';
    } else if (changeSinceLast > 0.5) {
      trendInsight = 'Weight increased slightly during the last 7 days.';
    } else {
      trendInsight = 'Weight remained stable this week.';
    }
  }

  return WeightMetrics(
    currentWeight: currentWeight,
    startWeight: startWeight,
    targetWeight: targetWeight,
    weightLost: weightLost,
    changeSinceLast: changeSinceLast,
    weeklyAverage: weeklyAverage,
    monthlyAverage: monthlyAverage,
    bmi: bmi,
    bmr: bmr,
    tdee: tdee,
    goalProgressPercentage: goalProgressPercentage,
    predictedGoalDate: predictedGoalDate,
    trendInsight: trendInsight,
  );
});

/// Automatically syncs computed metrics to the lightweight Dashboard stats document.
final dashboardStatsSyncProvider = Provider<void>((ref) {
  final metrics = ref.watch(weightMetricsProvider);
  final user = ref.watch(authControllerProvider).value;
  if (user == null || metrics.currentWeight == null) return;

  final stats = DashboardStatsModel(
    currentWeight: metrics.currentWeight!,
    weightLost: metrics.weightLost ?? 0,
    goalProgress: metrics.goalProgressPercentage ?? 0,
    latestBMI: metrics.bmi ?? 0,
    latestTDEE: metrics.tdee ?? 0,
    lastUpdated: DateTime.now(),
  );

  ref.read(dashboardStatsRepositoryProvider).updateStats(user.uid, stats);
});

/// Controller to handle adding/deleting weight entries.
class WeightController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Adds a new weight entry.
  Future<void> addEntry({
    required double weight,
    required DateTime date,
    String? note,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      final entry = WeightEntryModel(
        id: const Uuid().v4(),
        userId: user.uid,
        weight: weight,
        date: date,
        note: note?.isEmpty ?? true ? null : note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repository = ref.read(weightRepositoryProvider);
      await repository.addEntry(entry);

      // Also update the user's current weight in the profile.
      final updatedUser = user.copyWith(currentWeightKg: weight);
      await ref
          .read(authControllerProvider.notifier)
          .saveUserProfile(updatedUser);

      state = const AsyncData(null);

      _checkAchievements(weight, user.targetWeightKg);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Updates an existing weight entry.
  Future<void> updateEntry(WeightEntryModel entry) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(weightRepositoryProvider);
      final updated = entry.copyWith(updatedAt: DateTime.now());
      await repository.updateEntry(updated);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Deletes a weight entry.
  Future<void> deleteEntry(WeightEntryModel entry) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      final repository = ref.read(weightRepositoryProvider);
      await repository.deleteEntry(user.uid, entry.id);

      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Evaluates and triggers future achievement UI hooks.
  void _checkAchievements(double currentWeight, double? targetWeight) {
    ref.read(achievementEngineProvider).processWeightEvent(currentWeight);
  }
}

/// Provider for [WeightController].
final weightControllerProvider = AsyncNotifierProvider<WeightController, void>(
  () {
    return WeightController();
  },
);
