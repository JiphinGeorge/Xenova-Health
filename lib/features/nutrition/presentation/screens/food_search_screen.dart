import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/food_database_repository.dart';
import '../../domain/models/food_item_model.dart';
import '../controllers/food_search_controller.dart';
import '../controllers/meal_logging_controller.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomFoodModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final calsCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final gramsCtrl = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.spacingLg,
          right: AppDimensions.spacingLg,
          top: AppDimensions.spacingLg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimensions.spacingLg,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Custom Food',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Food Name',
                    hintText: 'e.g. Homemade Smoothie',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter food name' : null,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: gramsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Serving (g)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || double.tryParse(v) == null
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: TextFormField(
                        controller: calsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Calories (kcal)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || double.tryParse(v) == null
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: proteinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Protein (g)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || double.tryParse(v) == null
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: carbsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Carbs (g)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || double.tryParse(v) == null
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: fatCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fat (g)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || double.tryParse(v) == null
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final user = ref.read(authControllerProvider).value;
                    if (user == null) return;

                    final customFood = FoodItemModel(
                      id: 'custom_${const Uuid().v4()}',
                      name: nameCtrl.text.trim(),
                      calories: double.parse(calsCtrl.text.trim()),
                      protein: double.parse(proteinCtrl.text.trim()),
                      carbs: double.parse(carbsCtrl.text.trim()),
                      fat: double.parse(fatCtrl.text.trim()),
                      servingSizeGrams: double.parse(gramsCtrl.text.trim()),
                      isCustom: true,
                      createdByUserId: user.uid,
                      createdAt: DateTime.now(),
                    );

                    await ref
                        .read(foodDatabaseRepositoryProvider)
                        .addCustomFood(user.uid, customFood);

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      // Directly push to details to select serving size
                      context.push('/food-details', extra: customFood);
                    }
                  },
                  child: const Text('Save & Select'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(foodSearchResultsProvider);
    final builderState = ref.watch(mealLoggingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add to ${builderState.mealType}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add_outlined),
            tooltip: 'Custom Food',
            onPressed: () => _showAddCustomFoodModal(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: 8,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search foods (chicken, oats, eggs, rice...)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(foodSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                ref.read(foodSearchQueryProvider.notifier).state = val;
                setState(() {});
              },
            ),
          ),
        ),
      ),
      body: searchResults.when(
        data: (foods) {
          if (foods.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: AppDimensions.spacingMd),
                    const Text(
                      'No foods found for this search.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    FilledButton.tonalIcon(
                      onPressed: () => _showAddCustomFoodModal(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom Food'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: foods.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, index) {
              final food = foods[index];
              return ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        food.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (food.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Custom',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${food.calories.toStringAsFixed(0)} kcal • ${food.servingSizeGrams.toStringAsFixed(0)}g | P: ${food.protein.toStringAsFixed(1)}g  C: ${food.carbs.toStringAsFixed(1)}g  F: ${food.fat.toStringAsFixed(1)}g',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                trailing: const Icon(
                  Icons.add_circle,
                  color: AppColors.primary,
                ),
                onTap: () {
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
                    context.push('/meal-builder-review');
                  },
                  icon: const Icon(Icons.restaurant),
                  label: Text(
                    'Review ${builderState.mealType} (${builderState.items.length} items • ${builderState.totalCalories.toStringAsFixed(0)} kcal)',
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
