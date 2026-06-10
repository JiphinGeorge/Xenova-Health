import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/goal_progress_ring.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../fasting/presentation/controllers/fasting_controller.dart';
import '../../../progress_photos/presentation/controllers/progress_photos_controller.dart';
import '../../../progress_photos/presentation/widgets/add_progress_photo_dialog.dart';
import '../../../weight/presentation/controllers/weight_controller.dart';
import '../../../weight/presentation/widgets/add_weight_dialog.dart';
import '../../data/repositories/dashboard_stats_repository.dart';
import '../../../nutrition/presentation/controllers/nutrition_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showAddWeight(BuildContext context) {
    showDialog<void>(context: context, builder: (_) => const AddWeightDialog());
  }

  void _showAddPhoto(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const AddProgressPhotoDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep stats in sync
    ref.watch(dashboardStatsSyncProvider);

    final user = ref.watch(authControllerProvider).value;
    final name = user?.displayName?.split(' ').first ?? 'Xenova';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Welcome Card
              Text(
                '${_getGreeting()},',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXl),

              // 2. Weight Snapshot
              _buildWeightSnapshot(context, ref),
              const SizedBox(height: AppDimensions.spacingXl),

              // 2.1 Fasting Card
              _buildFastingCard(context, ref),
              const SizedBox(height: AppDimensions.spacingXl),

              // 3. Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Row(
                children: [
                  _QuickActionBtn(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Weight',
                    onTap: () => _showAddWeight(context),
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  _QuickActionBtn(
                    icon: Icons.restaurant_outlined,
                    label: 'Meal',
                    onTap: () {},
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  _QuickActionBtn(
                    icon: Icons.timer_outlined,
                    label: 'Fast',
                    onTap: () => context.push('/fasting'),
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  _QuickActionBtn(
                    icon: Icons.photo_camera_back_outlined,
                    label: 'Photo',
                    onTap: () => _showAddPhoto(context),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXl),

              // 4. Nutrition Card
              _buildNutritionCard(context, ref),
              const SizedBox(height: AppDimensions.spacingXl),

              // 5. Progress Photos (Existing)

              // 4. Today's Progress (Placeholders)
              Text(
                'Today\'s Progress',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDimensions.spacingMd,
                crossAxisSpacing: AppDimensions.spacingMd,
                childAspectRatio: 1.5,
                children: const [
                  _ProgressCard(
                    title: 'Calories',
                    subtitle: '1,200 / 2,000 kcal',
                    icon: Icons.local_fire_department,
                    progress: 0.6,
                    color: Colors.orange,
                  ),
                  _ProgressCard(
                    title: 'Protein',
                    subtitle: '80 / 150 g',
                    icon: Icons.fitness_center,
                    progress: 0.53,
                    color: Colors.blue,
                  ),
                  _ProgressCard(
                    title: 'Fasting',
                    subtitle: '14h 20m',
                    icon: Icons.timer,
                    progress: 0.8,
                    color: Colors.purple,
                  ),
                  _ProgressCard(
                    title: 'Water',
                    subtitle: '1.5 / 2.5 L',
                    icon: Icons.water_drop,
                    progress: 0.6,
                    color: Colors.cyan,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXl),

              // 5. AI Coach Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                    SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Coach Insight',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "You've been consistent with your weight logs! Keep it up. A 500 kcal deficit will get you to your goal safely.",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXl),

              // 6. Recent Activity
              Text(
                'Recent Activity',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              _buildRecentActivity(context, ref),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightSnapshot(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(weightEntriesStreamProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (entries == null || entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevatedDark : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              'Ready to start tracking?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingXs),
            const Text(
              'Log your first weight to unlock predictions, trends, and AI coaching insights.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            ElevatedButton.icon(
              onPressed: () => _showAddWeight(context),
              icon: const Icon(Icons.add),
              label: const Text('Add First Weight'),
            ),
          ],
        ),
      );
    }

    final metrics = ref.watch(weightMetricsProvider);

    final current = metrics.currentWeight ?? 0.0;
    final target = metrics.targetWeight ?? 0.0;
    final progress = metrics.goalProgressPercentage ?? 0.0;

    // Trend
    final change = metrics.changeSinceLast ?? 0.0;
    var trendIcon = Icons.trending_flat;
    var trendColor = AppColors.primary;
    if (change < 0) {
      trendIcon = Icons.trending_down;
      trendColor = AppColors.success;
    } else if (change > 0) {
      trendIcon = Icons.trending_up;
      trendColor = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevatedDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GoalProgressRing(
            progress: progress,
            size: 80,
            child: Icon(trendIcon, color: trendColor, size: 32),
          ),
          const SizedBox(width: AppDimensions.spacingXl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weight Goal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      current > 0 ? current.toStringAsFixed(1) : '--',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'kg',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${target > 0 ? target : "--"} kg',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsStreamProvider);
    return statsAsync.when(
      data: (stats) {
        final score = stats?.healthScore?.overallHealthScore ?? 0.0;
        String status = "Needs Improvement";
        Color color = AppColors.error;
        if (score >= 80) {
          status = "Excellent";
          color = AppColors.success;
        } else if (score >= 50) {
          status = "Good";
          color = AppColors.warning;
        }

        return Container(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Health Score',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${score.toInt()}/100',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNutritionCard(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(dailyNutritionSummaryStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Nutrition",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.push('/nutrition'),
              child: const Text('Details'),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.elevatedDark : AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: nutritionAsync.when(
            data: (summary) {
              if (summary == null) {
                return Column(
                  children: [
                    const Icon(Icons.restaurant, color: Colors.grey, size: 40),
                    const SizedBox(height: AppDimensions.spacingMd),
                    const Text('No meals logged today.'),
                    const SizedBox(height: AppDimensions.spacingMd),
                    FilledButton.tonal(
                      onPressed: () => context.push('/food-search'),
                      child: const Text('Log a Meal'),
                    ),
                  ],
                );
              }

              final pctCals = (summary.totalCalories / summary.targetCalories)
                  .clamp(0.0, 1.0);
              final proteinGoal = summary.targetProtein ?? 150.0;
              final pctProtein = (summary.totalProtein / proteinGoal).clamp(
                0.0,
                1.0,
              );
              final waterGoal = summary.waterGoalMl ?? 2500;
              final pctWater = (summary.waterIntakeMl / waterGoal).clamp(
                0.0,
                1.0,
              );
              final remaining = summary.targetCalories - summary.totalCalories;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatRing(
                    value: pctCals,
                    label:
                        '${remaining.clamp(0, double.infinity).toStringAsFixed(0)}',
                    subLabel: 'kcal left',
                    color: pctCals >= 1.0 ? AppColors.error : AppColors.primary,
                  ),
                  _StatRing(
                    value: pctProtein,
                    label: '${(pctProtein * 100).toStringAsFixed(0)}%',
                    subLabel: 'Protein',
                    color: Colors.blue,
                  ),
                  _StatRing(
                    value: pctWater,
                    label: '${(pctWater * 100).toStringAsFixed(0)}%',
                    subLabel: 'Water',
                    color: Colors.lightBlueAccent,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
          ),
        ),
      ],
    );
  }

  Widget _StatRing({
    required double value,
    required String label,
    required String subLabel,
    required Color color,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: color,
                strokeWidth: 6,
              ),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(subLabel, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildFastingCard(BuildContext context, WidgetRef ref) {
    final activeSessionAsync = ref.watch(activeFastingSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return activeSessionAsync.when(
      data: (session) {
        if (session == null) {
          return GestureDetector(
            onTap: () => context.push('/fasting'),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevatedDark : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.primarySurface),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer_outlined, color: AppColors.primary),
                      SizedBox(width: AppDimensions.spacingSm),
                      Text(
                        'Intermittent Fasting',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  const Text('No active fast. Ready to start?'),
                  const SizedBox(height: AppDimensions.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () {
                        context.push('/fasting');
                      },
                      child: const Text('Start Fast'),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  _buildFastingStatsRow(context, ref),
                ],
              ),
            ),
          );
        }

        final targetDuration = Duration(
          minutes: (session.targetDurationHours * 60).toInt(),
        );
        final elapsed = DateTime.now().difference(session.startTime);
        final progress = (elapsed.inSeconds / targetDuration.inSeconds).clamp(
          0.0,
          1.0,
        );
        final isGoalReached = elapsed >= targetDuration;

        return GestureDetector(
          onTap: () => context.push('/fasting'),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevatedDark : Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.primarySurface),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined, color: AppColors.primary),
                        SizedBox(width: AppDimensions.spacingSm),
                        Text(
                          'Current Fast',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isGoalReached ? 'Goal Reached!' : 'Fasting',
                      style: TextStyle(
                        color: isGoalReached
                            ? AppColors.success
                            : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton.extended(
                  onPressed: () => context.push(AppRoutes.aiCoach),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AI Coach'),
                ),
                body: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(dashboardStatsRepositoryProvider);
                    ref.invalidate(userProfileRepositoryProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppDimensions.spacingXl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppDimensions.spacingXl),
                        
                        // 1. Greeting
                        Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXl),

                        // Health Score
                        _buildHealthScoreCard(context, ref),
                        const SizedBox(height: AppDimensions.spacingXl),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: AppColors.primarySurface,
                        color: isGoalReached
                            ? AppColors.success
                            : AppColors.primary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingLg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Goal: ${session.targetDurationHours.toStringAsFixed(1)}h',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _buildFastingStatsRow(context, ref),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFastingStatsRow(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsStreamProvider);

    return statsAsync.when(
      data: (stats) {
        final currentStreak = stats?.currentFastingStreak ?? 0;
        final longestStreak = stats?.longestFastingStreak ?? 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  'Current Streak',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '$currentStreak Days',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Container(
              height: 30,
              width: 1,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            Column(
              children: [
                Text(
                  'Longest Streak',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '$longestStreak Days',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final weightEntries = ref.watch(weightEntriesStreamProvider).value;
    final photoEntries = ref.watch(progressPhotosStreamProvider).value;

    final hasWeight = weightEntries != null && weightEntries.isNotEmpty;
    final hasPhoto = photoEntries != null && photoEntries.isNotEmpty;

    if (!hasWeight && !hasPhoto) {
      return const Text(
        'No recent activity to show.',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return Column(
      children: [
        if (hasWeight)
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primarySurface,
              child: Icon(Icons.monitor_weight, color: AppColors.primaryDark),
            ),
            title: const Text('Logged Weight'),
            subtitle: Text('${weightEntries.first.weight} kg'),
            trailing: const Icon(Icons.chevron_right),
            contentPadding: EdgeInsets.zero,
          ),
        if (hasPhoto)
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primarySurface,
              child: Icon(Icons.photo, color: AppColors.primaryDark),
            ),
            title: const Text('Added Progress Photo'),
            subtitle: Text('${photoEntries.first.weightAtTime} kg'),
            trailing: const Icon(Icons.chevron_right),
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.spacingXs),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.progress,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppDimensions.spacingXs),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(subtitle, style: const TextStyle(fontSize: 12)),
          LinearProgressIndicator(
            value: progress,
            color: color,
            backgroundColor: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _StatRing extends StatelessWidget {
  const _StatRing({
    required this.value,
    required this.label,
    required this.subLabel,
    required this.color,
  });

  final double value;
  final String label;
  final String subLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: color.withValues(alpha: 0.2),
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subLabel,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
