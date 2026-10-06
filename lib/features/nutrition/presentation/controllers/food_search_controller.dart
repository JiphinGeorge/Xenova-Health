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
    // When empty query, display user custom foods plus all staple global foods
    await for (final customFoods in repo.watchCustomFoods(user.uid)) {
      final combined = <String, FoodItemModel>{};
      for (final f in customFoods) {
        combined[f.id] = f;
      }
      for (final f in FoodDatabaseRepository.defaultFoods) {
        combined[f.id] = f;
      }
      yield combined.values.toList();
      break;
    }
    return;
  }

  final trimmed = query.trim().toLowerCase();
  await for (final globalFoods in repo.searchGlobalFoods(trimmed)) {
    final map = <String, FoodItemModel>{};
    for (final f in globalFoods) {
      map[f.id] = f;
    }
    yield map.values.toList();
  }
});
