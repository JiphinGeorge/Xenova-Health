import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../domain/models/food_item_model.dart';
import '../controllers/meal_logging_controller.dart';

class FoodDetailsScreen extends ConsumerStatefulWidget {
  const FoodDetailsScreen({super.key, required this.food});

  final FoodItemModel food;

  @override
  ConsumerState<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends ConsumerState<FoodDetailsScreen> {
  late double _servingGrams;
  late String _selectedMealType;
  bool _isQuickLogging = false;

  @override
  void initState() {
    super.initState();
    _servingGrams = widget.food.servingSizeGrams;
    _selectedMealType = ref.read(mealLoggingProvider).mealType;
    if (_selectedMealType.trim().isEmpty) {
      _selectedMealType = 'Breakfast';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.food.servingSizeGrams > 0
        ? _servingGrams / widget.food.servingSizeGrams
        : 1.0;
    final calories = widget.food.calories * ratio;
    final protein = widget.food.protein * ratio;
    final carbs = widget.food.carbs * ratio;
    final fat = widget.food.fat * ratio;

    return Scaffold(
      appBar: AppBar(title: const Text('Portion & Nutrition')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.food.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.food.brandName != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.food.brandName!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
              const SizedBox(height: AppDimensions.spacingXl),

              // Macro Summary Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatText(
                      label: 'Calories',
                      val: calories.toStringAsFixed(0),
                      color: Colors.orange,
                    ),
                    _StatText(
                      label: 'Protein',
                      val: '${protein.toStringAsFixed(1)}g',
                      color: Colors.blue,
                    ),
                    _StatText(
                      label: 'Carbs',
                      val: '${carbs.toStringAsFixed(1)}g',
                      color: Colors.green,
                    ),
                    _StatText(
                      label: 'Fat',
                      val: '${fat.toStringAsFixed(1)}g',
                      color: Colors.amber[800] ?? Colors.amber,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXl),
              const Text(
                'Meal Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              // Meal Category Selector Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                  final isSelected =
                      _selectedMealType.toLowerCase() == type.toLowerCase();
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMealType = type);
                        ref
                            .read(mealLoggingProvider.notifier)
                            .setMealType(type);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: AppDimensions.spacingXl),
              const Text(
                'Serving Size (grams)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              // Quick Portion Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: Text(
                      '${widget.food.servingSizeGrams.round()}g (1 serving)',
                    ),
                    avatar: const Icon(Icons.check, size: 16),
                    onPressed: () => setState(
                      () => _servingGrams = widget.food.servingSizeGrams,
                    ),
                  ),
                  ActionChip(
                    label: const Text('50g'),
                    onPressed: () => setState(() => _servingGrams = 50),
                  ),
                  ActionChip(
                    label: const Text('100g'),
                    onPressed: () => setState(() => _servingGrams = 100),
                  ),
                  ActionChip(
                    label: const Text('150g'),
                    onPressed: () => setState(() => _servingGrams = 150),
                  ),
                  ActionChip(
                    label: const Text('200g'),
                    onPressed: () => setState(() => _servingGrams = 200),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spacingLg),
              Slider(
                value: _servingGrams.clamp(10, 1000),
                min: 10,
                max: 1000,
                divisions: 99,
                label: '${_servingGrams.round()} g',
                onChanged: (val) {
                  setState(() {
                    _servingGrams = val;
                  });
                },
              ),
              Text(
                '${_servingGrams.round()} grams',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXxl),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isQuickLogging
                      ? null
                      : () async {
                          setState(() => _isQuickLogging = true);
                          try {
                            await ref
                                .read(mealLoggingProvider.notifier)
                                .quickLogSingleFood(
                                  food: widget.food,
                                  servingConsumedGrams: _servingGrams,
                                  mealType: _selectedMealType,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Logged ${widget.food.name} to $_selectedMealType!',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              context.go('/nutrition');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to log food: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isQuickLogging = false);
                          }
                        },
                  icon: _isQuickLogging
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    'Log to $_selectedMealType Now',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(mealLoggingProvider.notifier)
                        .addFood(widget.food, _servingGrams);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${widget.food.name} to meal builder'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    context.pop();
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Add to Meal Builder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatText extends StatelessWidget {
  const _StatText({
    required this.label,
    required this.val,
    this.color,
  });

  final String label;
  final String val;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
