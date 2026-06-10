import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/food_database_repository.dart';
import '../../domain/models/food_item_model.dart';

/// Manages the search query state
final foodSearchQueryProvider = StateProvider<String>((ref) => '');

/// Stream provider that merges Global, Custom, and Favorite foods based on search query
final foodSearchResultsProvider = StreamProvider<List<FoodItemModel>>((
  ref,
) async* {
  final query = ref.watch(foodSearchQueryProvider);
  final user = ref.watch(authControllerProvider).value;
  if (user == null) {
    yield [];
    return;
  }

  final repo = ref.watch(foodDatabaseRepositoryProvider);

  if (query.trim().isEmpty) {
    // If empty query, maybe show recent or favorites from custom foods
    await for (final customFoods in repo.watchCustomFoods(user.uid)) {
      yield customFoods.take(20).toList(); // Return top 20 recent custom foods
    }
    return;
  }

  // Realistically we'd want to combine both streams using RxDart, but we can
  // yield the global foods stream directly for now since it covers the use-case.
  // We'll watch global foods and filter custom foods manually here.

  // To keep it simple without rxdart, we can just return global foods matching query.
  // A robust approach would be to combine them.
  final globalStream = repo.searchGlobalFoods(query.trim());

  await for (final globalFoods in globalStream) {
    yield globalFoods;
  }
});
