import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../controllers/meal_logging_controller.dart';

class MealBuilderReviewScreen extends ConsumerStatefulWidget {
  const MealBuilderReviewScreen({super.key});

  @override
  ConsumerState<MealBuilderReviewScreen> createState() =>
      _MealBuilderReviewScreenState();
}

class _MealBuilderReviewScreenState
    extends ConsumerState<MealBuilderReviewScreen> {
  String _mealType = 'Breakfast';

  final _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Pre-Workout',
    'Post-Workout',
  ];

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(mealLoggingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Meal')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _mealType,
                    decoration: const InputDecoration(labelText: 'Meal Type'),
                    items: _mealTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _mealType = val);
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatText(
                        label: 'Calories',
                        val: builderState.totalCalories.toStringAsFixed(0),
                      ),
                      _StatText(
                        label: 'Protein',
                        val: '${builderState.totalProtein.toStringAsFixed(1)}g',
                      ),
                      _StatText(
                        label: 'Carbs',
                        val: '${builderState.totalCarbs.toStringAsFixed(1)}g',
                      ),
                      _StatText(
                        label: 'Fat',
                        val: '${builderState.totalFat.toStringAsFixed(1)}g',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),
                  const Text(
                    'Foods in Meal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = builderState.items[index];
              return ListTile(
                title: Text(item.foodName),
                subtitle: Text(
                  '${item.servingConsumedGrams.toStringAsFixed(0)}g • ${item.calories.toStringAsFixed(0)} kcal',
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.error,
                  ),
                  onPressed: () {
                    ref.read(mealLoggingProvider.notifier).removeFood(index);
                    if (ref.read(mealLoggingProvider).items.isEmpty) {
                      context.pop();
                    }
                  },
                ),
              );
            }, childCount: builderState.items.length),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: FilledButton(
            onPressed: builderState.items.isEmpty
                ? null
                : () async {
                    await ref
                        .read(mealLoggingProvider.notifier)
                        .saveMeal(mealType: _mealType);
                    if (context.mounted) {
                      context.go('/nutrition');
                    }
                  },
            child: const Text('Save Meal'),
          ),
        ),
      ),
    );
  }
}

class _StatText extends StatelessWidget {
  const _StatText({required this.label, required this.val});
  final String label;
  final String val;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
