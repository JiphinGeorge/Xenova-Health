import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/daily_nutrition_summary_model.dart';
import '../controllers/nutrition_controller.dart';

class NutritionDashboardScreen extends ConsumerWidget {
  const NutritionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dailyNutritionSummaryStreamProvider);
    final mealsAsync = ref.watch(dailyMealLogsStreamProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) {
                ref.read(selectedDateProvider.notifier).state = picked;
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: summaryAsync.when(
              data: (summary) {
                if (summary == null) {
                  return const Padding(
                    padding: EdgeInsets.all(AppDimensions.spacingXl),
                    child: Center(
                      child: Text('No nutrition data logged for this date.'),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingLg),
                  child: Column(
                    children: [
                      _buildMacroOverview(context, summary),
                      const SizedBox(height: AppDimensions.spacingXl),
                      _buildWaterTracker(context, ref, summary),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: XenovaLoadingIndicator(),
                ),
              ),
              error: (e, st) => XenovaErrorWidget(message: e.toString()),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingLg,
                vertical: AppDimensions.spacingMd,
              ),
              child: Text(
                'Meals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          mealsAsync.when(
            data: (meals) {
              if (meals.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: AppDimensions.spacingMd),
                          Text(
                            'No meals logged yet.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final meal = meals[index];
                  return ListTile(
                    title: Text(meal.mealType),
                    subtitle: Text(
                      '${meal.totalCalories.toStringAsFixed(0)} kcal • ${meal.totalProtein.toStringAsFixed(0)}g protein',
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      onPressed: () {
                        ref
                            .read(nutritionControllerProvider.notifier)
                            .deleteMealLog(meal);
                      },
                    ),
                  );
                }, childCount: meals.length),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => SliverToBoxAdapter(
              child: XenovaErrorWidget(message: e.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/food-search');
        },
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
      ),
    );
  }

  Widget _buildMacroOverview(
    BuildContext context,
    DailyNutritionSummaryModel summary,
  ) {
    final targetCals = summary.targetCalories;
    final totalCals = summary.totalCalories;
    final pctCals = (totalCals / targetCals).clamp(0.0, 1.0);

    final targetPro = summary.targetProtein ?? 150.0;
    final totalPro = summary.totalProtein;
    final pctPro = (totalPro / targetPro).clamp(0.0, 1.0);

    final targetCarbs = summary.targetCarbs ?? 200.0;
    final totalCarbs = summary.totalCarbs;
    final pctCarbs = (totalCarbs / targetCarbs).clamp(0.0, 1.0);

    final targetFat = summary.targetFat ?? 65.0;
    final totalFat = summary.totalFat;
    final pctFat = (totalFat / targetFat).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: pctCals,
                    strokeWidth: 10,
                    backgroundColor: AppColors.primarySurface,
                    color: pctCals >= 1.0 ? AppColors.error : AppColors.primary,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${(targetCals - totalCals).clamp(0, double.infinity).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('kcal left', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MacroBar(
              label: 'Protein',
              pct: pctPro,
              val: totalPro,
              color: Colors.blue,
            ),
            _MacroBar(
              label: 'Carbs',
              pct: pctCarbs,
              val: totalCarbs,
              color: Colors.green,
            ),
            _MacroBar(
              label: 'Fat',
              pct: pctFat,
              val: totalFat,
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaterTracker(
    BuildContext context,
    WidgetRef ref,
    DailyNutritionSummaryModel summary,
  ) {
    final waterIntake = summary.waterIntakeMl;
    final waterGoal = summary.waterGoalMl ?? 2500;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevatedDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Water', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Text(
                '$waterIntake / $waterGoal ml',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () {
                  ref
                      .read(nutritionControllerProvider.notifier)
                      .logWater(ref.read(selectedDateProvider), -250);
                },
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: AppDimensions.spacingXl),
              IconButton.filled(
                onPressed: () {
                  ref
                      .read(nutritionControllerProvider.notifier)
                      .logWater(ref.read(selectedDateProvider), 250);
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.pct,
    required this.val,
    required this.color,
  });

  final String label;
  final double pct;
  final double val;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          width: 8,
          child: RotatedBox(
            quarterTurns: 3,
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.2),
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${val.toStringAsFixed(0)}g',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
