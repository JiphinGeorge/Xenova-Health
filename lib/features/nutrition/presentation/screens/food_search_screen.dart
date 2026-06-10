import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/error_widget.dart';
import '../controllers/food_search_controller.dart';
import '../controllers/meal_logging_controller.dart';

class FoodSearchScreen extends ConsumerWidget {
  const FoodSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(foodSearchResultsProvider);
    final builderState = ref.watch(mealLoggingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Food'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for foods...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                ref.read(foodSearchQueryProvider.notifier).state = val;
              },
            ),
          ),
        ),
      ),
      body: searchResults.when(
        data: (foods) {
          if (foods.isEmpty) {
            return const Center(child: Text('No foods found.'));
          }
          return ListView.builder(
            itemCount: foods.length,
            itemBuilder: (context, index) {
              final food = foods[index];
              return ListTile(
                title: Text(food.name),
                subtitle: Text(
                  '${food.calories.toStringAsFixed(0)} kcal • ${food.servingSizeGrams}g',
                ),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () {
                  // Show bottom sheet to add serving size, or navigate to details
                  context.push('/food-details', extra: food);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => XenovaErrorWidget(message: e.toString()),
      ),
      bottomNavigationBar: builderState.items.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                child: FilledButton.icon(
                  onPressed: () {
                    // Navigate to meal builder review
                    context.push('/meal-builder-review');
                  },
                  icon: const Icon(Icons.restaurant),
                  label: Text('Review Meal (${builderState.items.length})'),
                ),
              ),
            )
          : null,
    );
  }
}
