import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    _servingGrams = widget.food.servingSizeGrams;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _servingGrams / widget.food.servingSizeGrams;
    final calories = widget.food.calories * ratio;
    final protein = widget.food.protein * ratio;
    final carbs = widget.food.carbs * ratio;
    final fat = widget.food.fat * ratio;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Food')),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.food.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (widget.food.brandName != null)
              Text(
                widget.food.brandName!,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
            const SizedBox(height: AppDimensions.spacingXxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatText(label: 'Calories', val: calories.toStringAsFixed(0)),
                _StatText(
                  label: 'Protein',
                  val: '${protein.toStringAsFixed(1)}g',
                ),
                _StatText(label: 'Carbs', val: '${carbs.toStringAsFixed(1)}g'),
                _StatText(label: 'Fat', val: '${fat.toStringAsFixed(1)}g'),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            const Text(
              'Serving Size (g)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _servingGrams,
              min: 10,
              max: 1000,
              divisions: 99,
              label: _servingGrams.round().toString(),
              onChanged: (val) {
                setState(() {
                  _servingGrams = val;
                });
              },
            ),
            Text(
              '${_servingGrams.round()} grams',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                ref
                    .read(mealLoggingProvider.notifier)
                    .addFood(widget.food, _servingGrams);
                context.pop();
              },
              child: const Text('Add to Meal'),
            ),
          ],
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
