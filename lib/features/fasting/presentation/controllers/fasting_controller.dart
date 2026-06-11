import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../dashboard/data/repositories/dashboard_stats_repository.dart';
import '../../gamification/application/services/achievement_engine_service.dart';
import '../data/repositories/fasting_repository.dart';
import '../../domain/models/fasting_session_model.dart';

/// Controller for managing Intermittent Fasting operations.
class FastingController extends StateNotifier<AsyncValue<void>> {
  FastingController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  /// Starts a new fasting session.
  Future<void> startFast(FastingPlan plan, {double? customDuration}) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      final targetDuration = customDuration ?? plan.defaultDurationHours;
      final startTime = DateTime.now();

      final session = FastingSessionModel(
        id: const Uuid().v4(),
        userId: user.uid,
        planType: plan,
        startTime: startTime,
        targetDurationHours: targetDuration,
        completed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _ref.read(fastingRepositoryProvider).saveFastingSession(session);

      // Show Started notification immediately
      await _ref
          .read(notificationServiceProvider)
          .showNotification(
            id: session.id.hashCode ^ 1, // unique ID variation
            title: 'Fast Started',
            body: 'Your ${plan.displayName} fast has begun. You got this!',
          );

      // Schedule completion notification
      final targetDate = startTime.add(
        Duration(minutes: (targetDuration * 60).toInt()),
      );
      await _ref
          .read(notificationServiceProvider)
          .scheduleNotification(
            id: session.id.hashCode,
            title: 'Fasting Goal Reached!',
            body: 'You have completed your fasting goal. Great job!',
            scheduledDate: targetDate,
          );

      // Schedule 30-min reminder
      final reminderDate = targetDate.subtract(const Duration(minutes: 30));
      if (reminderDate.isAfter(DateTime.now())) {
        await _ref
            .read(notificationServiceProvider)
            .scheduleNotification(
              id: session.id.hashCode ^ 2,
              title: 'Almost There!',
              body: 'Only 30 minutes left until your fasting goal.',
              scheduledDate: reminderDate,
            );
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Ends the currently active fasting session.
  Future<void> endFast({bool force = false}) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(authControllerProvider).value;
      if (user == null) throw Exception('User not logged in');

      final activeSession = _ref.read(activeFastingSessionProvider).value;
      if (activeSession == null) throw Exception('No active fast found');

      final endTime = DateTime.now();
      final durationMinutes = endTime
          .difference(activeSession.startTime)
          .inMinutes;
      final targetMinutes = (activeSession.targetDurationHours * 60).toInt();

      final completed = force ? false : durationMinutes >= targetMinutes;
      final pct = (durationMinutes / targetMinutes).clamp(0.0, 1.0);

      final updated = activeSession.copyWith(
        endTime: endTime,
        durationMinutes: durationMinutes,
        completed: completed,
        actualDurationHours: durationMinutes / 60.0,
        plannedDurationHours: activeSession.targetDurationHours,
        completionPercentage: pct,
        updatedAt: DateTime.now(),
      );

      await _ref.read(fastingRepositoryProvider).updateFastingSession(updated);

      if (completed) {
        final statsRepo = _ref.read(dashboardStatsRepositoryProvider);
        final currentStatsStream = statsRepo.watchStats(user.uid);
        final currentStats = await currentStatsStream.first;

        int streak = currentStats?.currentFastingStreak ?? 0;
        int longest = currentStats?.longestFastingStreak ?? 0;
        final lastDate = currentStats?.lastFastDate;

        final today = DateTime(endTime.year, endTime.month, endTime.day);

        if (lastDate == null) {
          streak = 1;
        } else {
          final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
          final diff = today.difference(lastDay).inDays;
          if (diff == 1) {
            streak++;
          } else if (diff > 1) {
            streak = 1;
          }
        }

        if (streak > longest) longest = streak;

        if (currentStats != null) {
          await statsRepo.updateStats(
            user.uid,
            currentStats.copyWith(
              currentFastingStreak: streak,
              longestFastingStreak: longest,
              lastFastDate: today,
            ),
          );
        }

        // Gamification Hook
        _ref.read(achievementEngineProvider).processFastingEvent(streak, updated.elapsedDuration.inHours);
      }

      // Cancel pending completion and reminder notifications
      await _ref
          .read(notificationServiceProvider)
          .cancelNotification(activeSession.id.hashCode);
      await _ref
          .read(notificationServiceProvider)
          .cancelNotification(activeSession.id.hashCode ^ 2);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Manually deletes a fasting session from history.
  Future<void> deleteSession(FastingSessionModel session) async {
    try {
      await _ref
          .read(fastingRepositoryProvider)
          .deleteFastingSession(session.userId, session.id);
    } catch (e) {
      // Handle silently or emit state
    }
  }
}

final fastingControllerProvider =
    StateNotifierProvider<FastingController, AsyncValue<void>>((ref) {
      return FastingController(ref);
    });

final fastingHistoryProvider = StreamProvider<List<FastingSessionModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const Stream.empty();

  return ref.watch(fastingRepositoryProvider).watchFastingHistory(user.uid);
});

final activeFastingSessionProvider = Provider<AsyncValue<FastingSessionModel?>>(
  (ref) {
    final historyAsync = ref.watch(fastingHistoryProvider);

    return historyAsync.whenData((history) {
      if (history.isEmpty) return null;
      final latest = history.first;
      // An active fast is one that has not been ended
      if (latest.endTime == null) return latest;
      return null;
    });
  },
);

class FastingMetrics {
  final int longestFastMinutes;
  final int currentStreakDays;
  final double averageFastHours;
  final int weeklyFasts;
  final int monthlyFasts;
  final double averageCompletionRate;

  FastingMetrics({
    required this.longestFastMinutes,
    required this.currentStreakDays,
    required this.averageFastHours,
    required this.weeklyFasts,
    required this.monthlyFasts,
    required this.averageCompletionRate,
  });
}

final fastingMetricsProvider = Provider<FastingMetrics>((ref) {
  final historyAsync = ref.watch(fastingHistoryProvider);
  final history = historyAsync.value ?? [];

  if (history.isEmpty) {
    return FastingMetrics(
      longestFastMinutes: 0,
      currentStreakDays: 0,
      averageFastHours: 0,
      weeklyFasts: 0,
      monthlyFasts: 0,
      averageCompletionRate: 0.0,
    );
  }

  int maxDuration = 0;
  int totalDuration = 0;
  int completedCount = 0;
  double totalCompletionPercentage = 0.0;
  int weeklyFasts = 0;
  int monthlyFasts = 0;

  final now = DateTime.now();

  for (final session in history) {
    if (session.completed && session.durationMinutes != null) {
      if (session.durationMinutes! > maxDuration) {
        maxDuration = session.durationMinutes!;
      }
      totalDuration += session.durationMinutes!;
      completedCount++;
    }

    // Add up completion percentage
    if (session.endTime != null && session.completionPercentage != null) {
      totalCompletionPercentage += session.completionPercentage!;
    } else if (session.endTime != null) {
      // Fallback if field didn't exist
      final target = session.targetDurationHours * 60;
      final duration = session.durationMinutes ?? 0;
      totalCompletionPercentage += (duration / target).clamp(0.0, 1.0);
    }

    if (session.startTime.isAfter(now.subtract(const Duration(days: 7)))) {
      weeklyFasts++;
    }
    if (session.startTime.isAfter(now.subtract(const Duration(days: 30)))) {
      monthlyFasts++;
    }
  }

  final avg = completedCount > 0
      ? (totalDuration / completedCount) / 60.0
      : 0.0;

  // Calculate streak
  int streak = 0;
  DateTime? lastDate;

  // history is ordered newest first
  for (final session in history) {
    if (!session.completed) continue;
    final date = DateTime(
      session.startTime.year,
      session.startTime.month,
      session.startTime.day,
    );
    if (lastDate == null) {
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final diff = today.difference(date).inDays;
      if (diff <= 1) {
        streak = 1;
        lastDate = date;
      } else {
        break;
      }
    } else {
      final diff = lastDate.difference(date).inDays;
      if (diff == 1) {
        streak++;
        lastDate = date;
      } else if (diff > 1) {
        break;
      }
    }
  }

  final avgCompletion = history.where((s) => s.endTime != null).isEmpty
      ? 0.0
      : totalCompletionPercentage /
            history.where((s) => s.endTime != null).length;

  return FastingMetrics(
    longestFastMinutes: maxDuration,
    currentStreakDays: streak,
    averageFastHours: avg,
    weeklyFasts: weeklyFasts,
    monthlyFasts: monthlyFasts,
    averageCompletionRate: avgCompletion,
  );
});
