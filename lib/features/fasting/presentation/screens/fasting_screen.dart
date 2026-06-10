import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/fasting_session_model.dart';
import '../controllers/fasting_controller.dart';

class FastingScreen extends ConsumerWidget {
  const FastingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessionAsync = ref.watch(activeFastingSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Intermittent Fasting')),
      body: activeSessionAsync.when(
        data: (activeSession) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingLg),
                  child: Column(
                    children: [
                      if (activeSession != null)
                        _ActiveFastingView(session: activeSession)
                      else
                        const _StartFastingView(),
                      const SizedBox(height: AppDimensions.spacingXl),
                      const _FastingStatsGrid(),
                      const SizedBox(height: AppDimensions.spacingXl),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent Fasts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                    ],
                  ),
                ),
              ),
              const _FastingHistoryList(),
            ],
          );
        },
        loading: () => const Center(child: XenovaLoadingIndicator()),
        error: (e, st) =>
            Center(child: XenovaErrorWidget(message: e.toString())),
      ),
    );
  }
}

class _ActiveFastingView extends ConsumerStatefulWidget {
  const _ActiveFastingView({required this.session});

  final FastingSessionModel session;

  @override
  ConsumerState<_ActiveFastingView> createState() => _ActiveFastingViewState();
}

class _ActiveFastingViewState extends ConsumerState<_ActiveFastingView> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateElapsed(),
    );
  }

  void _updateElapsed() {
    if (mounted) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.session.startTime);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final targetDuration = Duration(
      minutes: (widget.session.targetDurationHours * 60).toInt(),
    );
    final progress = (_elapsed.inSeconds / targetDuration.inSeconds).clamp(
      0.0,
      1.0,
    );
    final isGoalReached = _elapsed >= targetDuration;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 16,
                backgroundColor: AppColors.primarySurface,
                color: isGoalReached ? AppColors.success : AppColors.primary,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isGoalReached ? 'Goal Reached!' : 'Fasting',
                  style: TextStyle(
                    color: isGoalReached
                        ? AppColors.success
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(_elapsed),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Goal: ${widget.session.targetDurationHours.toStringAsFixed(1)}h',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXl),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: () {
              ref.read(fastingControllerProvider.notifier).endFast();
            },
            style: FilledButton.styleFrom(
              backgroundColor: isGoalReached
                  ? AppColors.success
                  : AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              isGoalReached ? 'Complete Fast' : 'End Early',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _StartFastingView extends ConsumerStatefulWidget {
  const _StartFastingView();

  @override
  ConsumerState<_StartFastingView> createState() => _StartFastingViewState();
}

class _StartFastingViewState extends ConsumerState<_StartFastingView> {
  FastingPlan _selectedPlan = FastingPlan.sixteenEight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.timer_outlined, size: 64, color: AppColors.primary),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          'Ready to Fast?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Text(
          'Select a fasting plan to begin',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: FastingPlan.values.map((plan) {
            final isSelected = _selectedPlan == plan;
            return ChoiceChip(
              label: Text(plan.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedPlan = plan);
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.spacingXl),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: () {
              ref
                  .read(fastingControllerProvider.notifier)
                  .startFast(_selectedPlan);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'Start Fast',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FastingStatsGrid extends ConsumerWidget {
  const _FastingStatsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(fastingMetricsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildCard(String title, String value, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevatedDark : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final longestHours = (metrics.longestFastMinutes / 60).toStringAsFixed(1);
    final averageHours = metrics.averageFastHours.toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: buildCard(
            'Longest Fast',
            '${longestHours}h',
            Icons.emoji_events_outlined,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: buildCard(
            'Current Streak',
            '${metrics.currentStreakDays} Days',
            Icons.local_fire_department_outlined,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: buildCard(
            'Average Fast',
            '${averageHours}h',
            Icons.analytics_outlined,
          ),
        ),
      ],
    );
  }
}

class _FastingHistoryList extends ConsumerWidget {
  const _FastingHistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(fastingHistoryProvider);

    return historyAsync.when(
      data: (history) {
        final completedFasts = history.where((f) => f.endTime != null).toList();

        if (completedFasts.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingXxl,
                horizontal: AppDimensions.spacingLg,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 80,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    Text(
                      'No fasting sessions yet',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      'Start a fast to build your history.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final session = completedFasts[index];
            final dateStr =
                '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}-${session.startTime.day.toString().padLeft(2, '0')}';
            final durationHours = (session.durationMinutes ?? 0) / 60;

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: session.completed
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  session.completed
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: session.completed
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
              title: Text('${durationHours.toStringAsFixed(1)} Hours'),
              subtitle: Text('$dateStr • ${session.planType.displayName}'),
              trailing: Text(
                session.completed ? 'Goal Reached' : 'Ended Early',
                style: TextStyle(
                  color: session.completed
                      ? AppColors.success
                      : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }, childCount: completedFasts.length),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}
