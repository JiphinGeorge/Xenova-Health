import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
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
import '../../domain/models/health_score_model.dart';
import '../controllers/health_score_provider.dart';
import '../../../nutrition/presentation/controllers/nutrition_controller.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';
import '../../../profile/presentation/widgets/profile_photo_picker.dart';

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

  void _showQuickLogWater(BuildContext context, WidgetRef ref) {
    final customController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final summary =
                ref.watch(dailyNutritionSummaryStreamProvider).value;
            final waterGoal = summary?.waterGoalMl ?? 2500;
            final waterIntake = summary?.waterIntakeMl ?? 0;
            final pctWater = (waterIntake / waterGoal).clamp(0.0, 1.0);

            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusXxl),
                ),
              ),
              padding: EdgeInsets.only(
                top: AppDimensions.spacingLg,
                left: AppDimensions.spacingLg,
                right: AppDimensions.spacingLg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).padding.bottom +
                    AppDimensions.spacingLg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.water_drop, color: Color(0xFF0284C7)),
                            SizedBox(width: 8),
                            Text(
                              'Log Water Intake',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text(
                      'Daily Target: $waterGoal ml (${(waterGoal / 1000).toStringAsFixed(1)} L)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),

                    // Progress Card
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingMd),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                          color:
                              const Color(0xFF0284C7).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$waterIntake / $waterGoal ml',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pctWater,
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFF0284C7)
                                        .withValues(alpha: 0.2),
                                    color: const Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${(pctWater * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),

                    // Quick Presets
                    const Text(
                      'Quick Presets',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Row(
                      children: [
                        Expanded(
                          child: _waterPresetButton(
                            label: 'Cup',
                            amount: 250,
                            icon: Icons.local_cafe_outlined,
                            onTap: () {
                              ref
                                  .read(nutritionControllerProvider.notifier)
                                  .logWater(DateTime.now(), 250);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added 250 ml water 💧'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _waterPresetButton(
                            label: 'Glass',
                            amount: 350,
                            icon: Icons.local_drink_outlined,
                            onTap: () {
                              ref
                                  .read(nutritionControllerProvider.notifier)
                                  .logWater(DateTime.now(), 350);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added 350 ml water 💧'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _waterPresetButton(
                            label: 'Bottle',
                            amount: 500,
                            icon: Icons.water_drop_outlined,
                            onTap: () {
                              ref
                                  .read(nutritionControllerProvider.notifier)
                                  .logWater(DateTime.now(), 500);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added 500 ml water 💧'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _waterPresetButton(
                            label: 'Flask',
                            amount: 750,
                            icon: Icons.sports_bar_outlined,
                            onTap: () {
                              ref
                                  .read(nutritionControllerProvider.notifier)
                                  .logWater(DateTime.now(), 750);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added 750 ml water 💧'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),

                    // Custom Amount
                    const Text(
                      'Custom Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g. 300',
                              suffixText: 'ml',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMd,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                          ),
                          onPressed: () {
                            final val =
                                int.tryParse(customController.text.trim());
                            if (val != null && val > 0) {
                              ref
                                  .read(nutritionControllerProvider.notifier)
                                  .logWater(DateTime.now(), val);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added $val ml water 💧'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),

                    if (waterIntake > 0) ...[
                      const SizedBox(height: AppDimensions.spacingLg),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(nutritionControllerProvider.notifier)
                              .logWater(DateTime.now(), -250);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context)
                              .hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Removed 250 ml water'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 16),
                        label: const Text('Undo last 250 ml'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _waterPresetButton({
    required String label,
    required int amount,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0284C7), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '+${amount}ml',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep stats in sync
    ref.watch(dashboardStatsSyncProvider);
    ref.watch(autoSyncDashboardStatsProvider);

    final user = ref.watch(authControllerProvider).value;
    final name = user?.displayName?.split(' ').first ?? 'Xenova';

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.aiCoach),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI Coach'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsRepositoryProvider);
          ref.invalidate(authControllerProvider);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Welcome Card & Notification Bell
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                    Row(
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final unreadCount = ref.watch(notificationControllerProvider.notifier).unreadCount;
                            final hasUnread = unreadCount > 0;
                            
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  onPressed: () => context.push(AppRoutes.notifications),
                                  icon: Icon(
                                    hasUnread ? Icons.notifications_active : Icons.notifications_none,
                                    color: hasUnread ? AppColors.error : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (hasUnread)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.profile),
                          child: const ProfilePhotoPicker(radius: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                // Health Score Card
                _buildHealthScoreCard(context, ref),
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
                  const SizedBox(width: AppDimensions.spacingXs),
                  _QuickActionBtn(
                    icon: Icons.restaurant_outlined,
                    label: 'Meal',
                    onTap: () => context.push('/nutrition'),
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
                  _QuickActionBtn(
                    icon: Icons.timer_outlined,
                    label: 'Fast',
                    onTap: () => context.push('/fasting'),
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
                  _QuickActionBtn(
                    icon: Icons.water_drop_outlined,
                    label: 'Water',
                    onTap: () => _showQuickLogWater(context, ref),
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
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

              // 5. Water / Hydration Tracker Card
              _buildWaterTrackerCard(context, ref),
              const SizedBox(height: AppDimensions.spacingXl),

              // 6. Today's Progress (Live Dynamic Stats)
              _buildTodaysProgress(context, ref),
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
    ));
  }

  Widget _buildWeightSnapshot(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(weightEntriesStreamProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (entries == null || entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : const Color.fromRGBO(60, 48, 32, 0.04),
              blurRadius: 16,
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
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color.fromRGBO(60, 48, 32, 0.04),
            blurRadius: 16,
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
    final healthScore = ref.watch(healthScoreProvider);
    final score = healthScore.overallHealthScore;

    String status = "Needs Focus";
    Color color = AppColors.error;
    IconData statusIcon = Icons.health_and_safety_outlined;

    if (score >= 80) {
      status = "Excellent";
      color = AppColors.success;
      statusIcon = Icons.verified_outlined;
    } else if (score >= 50) {
      status = "Good";
      color = AppColors.primary;
      statusIcon = Icons.thumb_up_alt_outlined;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showHealthScoreBreakdown(context, healthScore),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 28),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overall Health Score',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${score.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        '/100',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tap to view 4-pillar breakdown & tips',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHealthScoreBreakdown(
    BuildContext context,
    HealthScoreModel healthScore,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = healthScore.overallHealthScore;

    String status = "Needs Focus";
    Color color = AppColors.error;
    if (score >= 80) {
      status = "Excellent";
      color = AppColors.success;
    } else if (score >= 50) {
      status = "Good";
      color = AppColors.primary;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXxl),
            ),
          ),
          padding: EdgeInsets.only(
            top: AppDimensions.spacingLg,
            left: AppDimensions.spacingLg,
            right: AppDimensions.spacingLg,
            bottom: MediaQuery.of(ctx).padding.bottom + AppDimensions.spacingLg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Health Score Breakdown',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  'Calculated continuously across your 4 core lifestyle & physiological pillars.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),

                // Overall Score Highlight Card
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingLg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${score.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              score >= 80
                                  ? 'Superb performance across nutrition, fasting, and hydration!'
                                  : score >= 50
                                      ? 'Solid baseline. A few healthy choices will push you into Excellent.'
                                      : 'Log your meals, track fasting, and hydrate to raise your score.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                Text(
                  'Core Health Pillars',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMd),

                _buildPillarRow(
                  context: ctx,
                  icon: Icons.restaurant_menu,
                  iconColor: Colors.orange,
                  title: 'Nutrition & Macros',
                  weight: '35% weight',
                  score: healthScore.nutritionScore,
                  desc: 'Calorie compliance, protein targets, and meal logging frequency.',
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                _buildPillarRow(
                  context: ctx,
                  icon: Icons.timer_outlined,
                  iconColor: Colors.purple,
                  title: 'Intermittent Fasting',
                  weight: '25% weight',
                  score: healthScore.fastingScore,
                  desc: 'Active fast progress, target completion, and weekly streaks.',
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                _buildPillarRow(
                  context: ctx,
                  icon: Icons.monitor_weight_outlined,
                  iconColor: Colors.teal,
                  title: 'Weight & Consistency',
                  weight: '25% weight',
                  score: healthScore.weightConsistencyScore,
                  desc: 'Weigh-in consistency, BMI status, and goal progress.',
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                _buildPillarRow(
                  context: ctx,
                  icon: Icons.water_drop_outlined,
                  iconColor: Colors.blue,
                  title: 'Hydration',
                  weight: '15% weight',
                  score: healthScore.waterScore,
                  desc: 'Daily water intake adherence vs recommended daily goal.',
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                // Tips Section
                Text(
                  'Actionable Tips to Boost Your Score',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                ..._generateHealthTips(healthScore).map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.arrow_right,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.push('/nutrition');
                        },
                        icon: const Icon(Icons.restaurant, size: 16),
                        label: const Text('Log Meal'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          context.push('/fasting');
                        },
                        icon: const Icon(Icons.timer, size: 16),
                        label: const Text('Fasting Timer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillarRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String weight,
    required double score,
    required String desc,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoreColor = score >= 80
        ? AppColors.success
        : score >= 50
            ? AppColors.primary
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.elevatedDark
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Text(
                weight,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${score.toInt()}/100',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: scoreColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 100.0).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              color: scoreColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _generateHealthTips(HealthScoreModel healthScore) {
    final tips = <String>[];
    if (healthScore.waterScore < 80) {
      tips.add('Drink 1-2 more glasses of water today to hit your 2.5L hydration goal (+${(80 - healthScore.waterScore).toInt()} pts).');
    }
    if (healthScore.nutritionScore < 75) {
      tips.add('Log your meals consistently and hit your daily protein goal (+${(75 - healthScore.nutritionScore).toInt()} pts).');
    }
    if (healthScore.fastingScore < 75) {
      tips.add('Complete your current fast or build a streak to advance your metabolic health score.');
    }
    if (healthScore.weightConsistencyScore < 75) {
      tips.add('Record your weight at least once a week to maintain your tracking consistency score.');
    }
    if (tips.isEmpty) {
      tips.add('Keep up your daily routine! All 4 pillars are operating at peak performance.');
    }
    return tips;
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
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color.fromRGBO(60, 48, 32, 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: nutritionAsync.when(
            data: (summary) {
              final targetCals = summary?.targetCalories ?? 2000.0;
              final totalCals = summary?.totalCalories ?? 0.0;
              final pctCals = (totalCals / targetCals).clamp(0.0, 1.0);
              final proteinGoal = summary?.targetProtein ?? 150.0;
              final totalProtein = summary?.totalProtein ?? 0.0;
              final pctProtein = (totalProtein / proteinGoal).clamp(0.0, 1.0);
              final waterGoal = summary?.waterGoalMl ?? 2500;
              final waterIntake = summary?.waterIntakeMl ?? 0;
              final pctWater = (waterIntake / waterGoal).clamp(0.0, 1.0);
              final remaining = (targetCals - totalCals).clamp(0.0, double.infinity);

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatRing(
                        value: pctCals,
                        label: remaining.toStringAsFixed(0),
                        subLabel: 'kcal left',
                        color: pctCals >= 1.0 ? AppColors.error : AppColors.primary,
                      ),
                      _StatRing(
                        value: pctProtein,
                        label: '${totalProtein.toStringAsFixed(0)}g',
                        subLabel: 'Protein',
                        color: Colors.blue,
                      ),
                      _StatRing(
                        value: pctWater,
                        label: '${(waterIntake / 1000).toStringAsFixed(1)}L',
                        subLabel: 'Water',
                        color: Colors.lightBlueAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        summary == null || summary.mealCount == 0
                            ? 'No meals logged yet today'
                            : '${summary.mealCount} meal${summary.mealCount > 1 ? 's' : ''} logged (${totalCals.toStringAsFixed(0)} kcal)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

  Widget _buildWaterTrackerCard(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(dailyNutritionSummaryStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return nutritionAsync.when(
      data: (summary) {
        final waterGoal = summary?.waterGoalMl ?? 2500;
        final waterIntake = summary?.waterIntakeMl ?? 0;
        final pctWater = (waterIntake / waterGoal).clamp(0.0, 1.0);
        final glasses = (waterIntake / 250).floor();
        final goalGlasses = (waterGoal / 250).ceil();
        final percentText = (pctWater * 100).toInt();
        final isGoalMet = waterIntake >= waterGoal;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hydration',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showQuickLogWater(context, ref),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Quick Log'),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : const Color.fromRGBO(60, 48, 32, 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.hydration.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.water_drop,
                          color: AppColors.hydration,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${(waterIntake / 1000).toStringAsFixed(1)} / ${(waterGoal / 1000).toStringAsFixed(1)} L',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                if (isGoalMet)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Goal Met 🎉',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$glasses of $goalGlasses glasses • $percentText% of daily goal',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pctWater,
                      minHeight: 10,
                      backgroundColor: isDark
                          ? AppColors.hydration.withValues(alpha: 0.15)
                          : AppColors.hydration.withValues(alpha: 0.1),
                      color: AppColors.hydration,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (waterIntake > 0) ...[
                        IconButton.outlined(
                          tooltip: 'Undo 250ml',
                          onPressed: () {
                            ref
                                .read(nutritionControllerProvider.notifier)
                                .logWater(DateTime.now(), -250);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Removed 250 ml water'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.remove, size: 16),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                      ],
                      FilledButton.tonalIcon(
                        onPressed: () {
                          ref
                              .read(nutritionControllerProvider.notifier)
                              .logWater(DateTime.now(), 250);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added 250 ml water 💧'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('+250 ml'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.elevatedDark
                              : AppColors.hydration.withValues(alpha: 0.15),
                          foregroundColor: isDark
                              ? AppColors.hydration
                              : AppColors.hydration,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          ref
                              .read(nutritionControllerProvider.notifier)
                              .logWater(DateTime.now(), 500);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added 500 ml water 💧'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('+500 ml'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.hydration,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildTodaysProgress(BuildContext context, WidgetRef ref) {
    final nutritionAsync = ref.watch(dailyNutritionSummaryStreamProvider);
    final activeSessionAsync = ref.watch(activeFastingSessionProvider);

    final summary = nutritionAsync.value;
    final targetCals = summary?.targetCalories ?? 2000.0;
    final totalCals = summary?.totalCalories ?? 0.0;
    final pctCals = (totalCals / targetCals).clamp(0.0, 1.0);

    final targetProtein = summary?.targetProtein ?? 150.0;
    final totalProtein = summary?.totalProtein ?? 0.0;
    final pctProtein = (totalProtein / targetProtein).clamp(0.0, 1.0);

    final waterGoal = summary?.waterGoalMl ?? 2500;
    final waterIntake = summary?.waterIntakeMl ?? 0;
    final pctWater = (waterIntake / waterGoal).clamp(0.0, 1.0);

    final session = activeSessionAsync.value;
    String fastingSubtitle = 'Not Fasting';
    double fastingProgress = 0.0;
    if (session != null) {
      final elapsed = DateTime.now().difference(session.startTime);
      final hours = elapsed.inHours;
      final minutes = elapsed.inMinutes.remainder(60);
      fastingSubtitle = '${hours}h ${minutes}m';
      final targetMinutes = (session.targetDurationHours * 60).toInt();
      fastingProgress = targetMinutes > 0
          ? (elapsed.inMinutes / targetMinutes).clamp(0.0, 1.0)
          : 0.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Today's Progress",
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
          children: [
            GestureDetector(
              onTap: () => context.push('/nutrition'),
              child: _ProgressCard(
                title: 'Calories',
                subtitle:
                    '${totalCals.toStringAsFixed(0)} / ${targetCals.toStringAsFixed(0)} kcal',
                icon: Icons.local_fire_department,
                progress: pctCals,
                color: Colors.orange,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/nutrition'),
              child: _ProgressCard(
                title: 'Protein',
                subtitle:
                    '${totalProtein.toStringAsFixed(0)} / ${targetProtein.toStringAsFixed(0)} g',
                icon: Icons.fitness_center,
                progress: pctProtein,
                color: Colors.blue,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/fasting'),
              child: _ProgressCard(
                title: 'Fasting',
                subtitle: fastingSubtitle,
                icon: Icons.timer,
                progress: fastingProgress,
                color: Colors.purple,
              ),
            ),
            GestureDetector(
              onTap: () => _showQuickLogWater(context, ref),
              child: _ProgressCard(
                title: 'Water',
                subtitle:
                    '${(waterIntake / 1000).toStringAsFixed(1)} / ${(waterGoal / 1000).toStringAsFixed(1)} L',
                icon: Icons.water_drop,
                progress: pctWater,
                color: Colors.cyan,
              ),
            ),
          ],
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
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : const Color.fromRGBO(60, 48, 32, 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
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
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : const Color.fromRGBO(60, 48, 32, 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : const Color.fromRGBO(60, 48, 32, 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
