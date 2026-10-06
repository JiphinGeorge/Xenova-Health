import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/food_database_repository.dart';
import '../../domain/models/daily_nutrition_summary_model.dart';
import '../../domain/models/meal_log_model.dart';
import '../controllers/meal_logging_controller.dart';
import '../controllers/nutrition_controller.dart';

class NutritionDashboardScreen extends ConsumerStatefulWidget {
  const NutritionDashboardScreen({super.key});

  @override
  ConsumerState<NutritionDashboardScreen> createState() =>
      _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState
    extends ConsumerState<NutritionDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure the global food database is seeded for search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodDatabaseRepositoryProvider).seedGlobalDatabase();
    });
  }

  DailyNutritionSummaryModel _getEffectiveSummary(
    DailyNutritionSummaryModel? summary,
    DateTime selectedDate, [
    List<MealLogModel>? meals,
  ]) {
    final user = ref.read(authControllerProvider).value;
    final dateString =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    double totalCals = summary?.totalCalories ?? 0.0;
    double totalProtein = summary?.totalProtein ?? 0.0;
    double totalCarbs = summary?.totalCarbs ?? 0.0;
    double totalFat = summary?.totalFat ?? 0.0;
    int mealCount = summary?.mealCount ?? 0;

    // Self-healing fallback: if summary is missing or 0 but meals were logged for this date
    if (meals != null && meals.isNotEmpty) {
      final computedCals =
          meals.fold<double>(0, (sum, m) => sum + m.totalCalories);
      final computedProtein =
          meals.fold<double>(0, (sum, m) => sum + m.totalProtein);
      final computedCarbs =
          meals.fold<double>(0, (sum, m) => sum + m.totalCarbs);
      final computedFat =
          meals.fold<double>(0, (sum, m) => sum + m.totalFat);

      if (totalCals == 0 || computedCals > totalCals) {
        totalCals = computedCals;
        totalProtein = computedProtein;
        totalCarbs = computedCarbs;
        totalFat = computedFat;
        mealCount = meals.length;
      }
    }

    final targetCals = summary?.targetCalories ?? 2000.0;
    final targetProtein = summary?.targetProtein ?? 150.0;
    final targetCarbs = summary?.targetCarbs ?? 200.0;
    final targetFat = summary?.targetFat ?? 65.0;

    return DailyNutritionSummaryModel(
      userId: user?.uid ?? 'guest_user',
      dateString: dateString,
      totalCalories: totalCals,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      waterIntakeMl: summary?.waterIntakeMl ?? 0,
      waterGoalMl: summary?.waterGoalMl ?? 2500,
      targetCalories: targetCals,
      targetProtein: targetProtein,
      targetCarbs: targetCarbs,
      targetFat: targetFat,
      remainingCalories: (targetCals - totalCals).clamp(0.0, double.infinity),
      mealCount: mealCount,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dailyNutritionSummaryStreamProvider);
    final mealsAsync = ref.watch(dailyMealLogsStreamProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Nutrition'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Log Food',
            onPressed: () {
              ref.read(mealLoggingProvider.notifier).setMealType('Breakfast');
              context.push('/food-search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Date',
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
          // 1. Date Selector Strip
          SliverToBoxAdapter(
            child: _buildDateStrip(context, ref, selectedDate),
          ),

          // 2. Calorie & Macro Target Overview
          SliverToBoxAdapter(
            child: summaryAsync.when(
              data: (summary) {
                final effective = _getEffectiveSummary(
                  summary,
                  selectedDate,
                  mealsAsync.value,
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingLg,
                  ),
                  child: Column(
                    children: [
                      _buildMacroOverview(context, effective),
                      const SizedBox(height: AppDimensions.spacingLg),
                      _buildWaterTracker(context, ref, effective),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppDimensions.spacingXl),
                child: Center(child: XenovaLoadingIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                child: XenovaErrorWidget(message: e.toString()),
              ),
            ),
          ),

          // 3. Meals Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppDimensions.spacingLg,
                right: AppDimensions.spacingLg,
                top: AppDimensions.spacingXl,
                bottom: AppDimensions.spacingSm,
              ),
              child: Text(
                'Meals Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 4. Meal Categories (Breakfast, Lunch, Dinner, Snacks)
          mealsAsync.when(
            data: (meals) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingLg,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildMealSection(
                      context,
                      ref,
                      title: 'Breakfast',
                      icon: Icons.breakfast_dining_outlined,
                      color: Colors.amber,
                      meals: meals
                          .where((m) => m.mealType.toLowerCase() == 'breakfast')
                          .toList(),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    _buildMealSection(
                      context,
                      ref,
                      title: 'Lunch',
                      icon: Icons.lunch_dining_outlined,
                      color: Colors.orange,
                      meals: meals
                          .where((m) => m.mealType.toLowerCase() == 'lunch')
                          .toList(),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    _buildMealSection(
                      context,
                      ref,
                      title: 'Dinner',
                      icon: Icons.dinner_dining_outlined,
                      color: Colors.deepOrange,
                      meals: meals
                          .where((m) => m.mealType.toLowerCase() == 'dinner')
                          .toList(),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    _buildMealSection(
                      context,
                      ref,
                      title: 'Snack',
                      icon: Icons.apple_outlined,
                      color: Colors.green,
                      meals: meals
                          .where(
                            (m) =>
                                m.mealType.toLowerCase().contains('snack') ||
                                m.mealType.toLowerCase().contains('workout'),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 80), // Padding for FAB
                  ]),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.spacingXl),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (e, st) => SliverToBoxAdapter(
              child: XenovaErrorWidget(message: e.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(mealLoggingProvider.notifier).setMealType('Breakfast');
          context.push('/food-search');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
      ),
    );
  }

  Widget _buildDateStrip(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    String dateLabel = DateFormat('EEE, MMM d').format(selectedDate);
    if (isToday) {
      dateLabel = 'Today, ${DateFormat('MMM d').format(selectedDate)}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingMd,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Day',
            onPressed: () {
              ref.read(selectedDateProvider.notifier).state = selectedDate
                  .subtract(const Duration(days: 1));
            },
          ),
          InkWell(
            onTap: () async {
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
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Day',
            onPressed: () {
              ref.read(selectedDateProvider.notifier).state = selectedDate.add(
                const Duration(days: 1),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMacroOverview(
    BuildContext context,
    DailyNutritionSummaryModel summary,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetCals = summary.targetCalories;
    final totalCals = summary.totalCalories;
    final remaining = (targetCals - totalCals).clamp(0.0, double.infinity);
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

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevatedDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Ring Graphic
              SizedBox(
                height: 110,
                width: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        value: pctCals,
                        strokeWidth: 9,
                        backgroundColor: AppColors.primarySurface,
                        color: pctCals >= 1.0
                            ? AppColors.error
                            : AppColors.primary,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          remaining.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'kcal left',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingLg),
              // Calorie breakdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Consumed', style: TextStyle(fontSize: 13)),
                        Text(
                          '${totalCals.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Goal',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          '${targetCals.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pctCals,
                        minHeight: 8,
                        backgroundColor: AppColors.primarySurface,
                        color: pctCals >= 1.0
                            ? AppColors.error
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.spacingLg),
          // Macronutrient Progress Bars
          Row(
            children: [
              Expanded(
                child: _buildMacroProgress(
                  label: 'Protein',
                  consumed: totalPro,
                  target: targetPro,
                  pct: pctPro,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: _buildMacroProgress(
                  label: 'Carbs',
                  consumed: totalCarbs,
                  target: targetCarbs,
                  pct: pctCarbs,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: _buildMacroProgress(
                  label: 'Fat',
                  consumed: totalFat,
                  target: targetFat,
                  pct: pctFat,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgress({
    required String label,
    required double consumed,
    required double target,
    required double pct,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
            Text(
              '${consumed.toStringAsFixed(0)}/${target.toStringAsFixed(0)}g',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
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
    final pctWater = (waterIntake / waterGoal).clamp(0.0, 1.0);
    final glasses = (waterIntake / 250).floor();
    final goalGlasses = (waterGoal / 250).ceil();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevatedDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hydration',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Flexible(
                child: Text(
                  '$waterIntake / $waterGoal ml • $glasses/$goalGlasses glasses',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pctWater,
              minHeight: 8,
              backgroundColor: Colors.blue.withValues(alpha: 0.12),
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (waterIntake > 0)
                IconButton.outlined(
                  tooltip: 'Subtract 250ml',
                  onPressed: () {
                    ref
                        .read(nutritionControllerProvider.notifier)
                        .logWater(ref.read(selectedDateProvider), -250);
                  },
                  icon: const Icon(Icons.remove, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
              FilledButton.tonalIcon(
                onPressed: () {
                  ref
                      .read(nutritionControllerProvider.notifier)
                      .logWater(ref.read(selectedDateProvider), 250);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+250 ml'),
              ),
              FilledButton.icon(
                onPressed: () {
                  ref
                      .read(nutritionControllerProvider.notifier)
                      .logWater(ref.read(selectedDateProvider), 500);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+500 ml'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required Color color,
    required List<MealLogModel> meals,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalMealCals = meals.fold<double>(
      0,
      (sum, m) => sum + m.totalCalories,
    );
    final totalMealProtein = meals.fold<double>(
      0,
      (sum, m) => sum + m.totalProtein,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevatedDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Meal Section Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (totalMealCals > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${totalMealCals.toStringAsFixed(0)} kcal • ${totalMealProtein.toStringAsFixed(0)}g P)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    ref.read(mealLoggingProvider.notifier).setMealType(title);
                    context.push('/food-search');
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),

          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.spacingMd,
                right: AppDimensions.spacingMd,
                bottom: AppDimensions.spacingMd,
              ),
              child: InkWell(
                onTap: () {
                  ref.read(mealLoggingProvider.notifier).setMealType(title);
                  context.push('/food-search');
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.25,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '+ Add $title food',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meals.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final meal = meals[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMd,
                    vertical: AppDimensions.spacingSm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (meal.mealItems.isNotEmpty)
                              ...meal.mealItems.map(
                                (item) => Text(
                                  item.foodName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              Text(
                                meal.mealName ?? meal.mealType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              '${meal.totalCalories.toStringAsFixed(0)} kcal • ${meal.totalProtein.toStringAsFixed(1)}g P • ${meal.totalCarbs.toStringAsFixed(1)}g C • ${meal.totalFat.toStringAsFixed(1)}g F',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AppColors.error,
                        ),
                        tooltip: 'Delete Log',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Meal Log?'),
                              content: const Text(
                                'Are you sure you want to remove this logged meal? Your macros will be deducted automatically.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref
                                .read(nutritionControllerProvider.notifier)
                                .deleteMealLog(meal);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
