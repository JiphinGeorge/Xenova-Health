import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/food_item_model.dart';

class FoodDatabaseRepository {
  FoodDatabaseRepository(this._firestoreService, this._firestore);

  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore;

  String _globalFoodsPath() => 'food_database';
  String _customFoodsPath(String userId) => 'users/$userId/custom_foods';

  /// Watches global foods based on a query
  Stream<List<FoodItemModel>> searchGlobalFoods(String query) {
    // Case-insensitive prefix search using a lowercased 'searchName' field.
    // Falls back to 'name' field for data without searchName.
    final lowerQuery = query.toLowerCase();
    return _firestore
        .collection(_globalFoodsPath())
        .where('searchName', isGreaterThanOrEqualTo: lowerQuery)
        .where('searchName', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FoodItemModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Watches custom foods for a specific user
  Stream<List<FoodItemModel>> watchCustomFoods(String userId) {
    return _firestore
        .collection(_customFoodsPath(userId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FoodItemModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Adds a custom food item
  Future<void> addCustomFood(String userId, FoodItemModel food) async {
    await _firestoreService.setDocument(
      path: '${_customFoodsPath(userId)}/${food.id}',
      data: food.toJson(),
    );
  }

  /// Deletes a custom food item
  Future<void> deleteCustomFood(String userId, String foodId) async {
    await _firestoreService.deleteDocument(
      '${_customFoodsPath(userId)}/$foodId',
    );
  }

  /// Seeds the global food database with common foods if it's empty
  Future<void> seedGlobalDatabase() async {
    try {
      final collection = _firestore.collection(_globalFoodsPath());
      
      // Check if already seeded with searchName field
      final snapshot = await collection.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final firstDoc = snapshot.docs.first.data();
        if (firstDoc.containsKey('searchName')) {
          // Already seeded with searchName
          return;
        }
        // Old data without searchName — delete and reseed
        final allDocs = await collection.get();
        final deleteBatch = _firestore.batch();
        for (final doc in allDocs.docs) {
          deleteBatch.delete(doc.reference);
        }
        await deleteBatch.commit();
      }

      final batch = _firestore.batch();

    final foods = [
      // Proteins
      FoodItemModel(
        id: 'global_egg',
        name: 'Egg (Large)',
        calories: 72,
        protein: 6.3,
        carbs: 0.4,
        fat: 4.8,
        servingSizeGrams: 50,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_chicken_breast',
        name: 'Chicken Breast (Raw)',
        calories: 120,
        protein: 22.5,
        carbs: 0.0,
        fat: 2.6,
        servingSizeGrams: 100,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_tuna',
        name: 'Canned Tuna (in water)',
        calories: 90,
        protein: 20.0,
        carbs: 0.0,
        fat: 1.0,
        servingSizeGrams: 100,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_salmon',
        name: 'Salmon (Raw)',
        calories: 208,
        protein: 20.0,
        carbs: 0.0,
        fat: 13.0,
        servingSizeGrams: 100,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_tofu',
        name: 'Firm Tofu',
        calories: 144,
        protein: 15.8,
        carbs: 2.8,
        fat: 8.7,
        servingSizeGrams: 100,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_soya_chunks',
        name: 'Soya Chunks',
        calories: 345,
        protein: 52.0,
        carbs: 33.0,
        fat: 0.5,
        servingSizeGrams: 100,
        isVerified: true,
      ),

      // Carbohydrates
      FoodItemModel(
        id: 'global_white_rice',
        name: 'White Rice (Cooked)',
        calories: 130,
        protein: 2.7,
        carbs: 28.0,
        fat: 0.3,
        servingSizeGrams: 100,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_brown_rice',
        name: 'Brown Rice (Cooked)',
        calories: 111,
        protein: 2.6,
        carbs: 23.0,
        fat: 0.9,
        servingSizeGrams: 100,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_oats',
        name: 'Rolled Oats (Raw)',
        calories: 389,
        protein: 16.9,
        carbs: 66.3,
        fat: 6.9,
        servingSizeGrams: 100,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_whole_wheat_bread',
        name: 'Whole Wheat Bread',
        calories: 247,
        protein: 13.0,
        carbs: 41.0,
        fat: 3.4,
        servingSizeGrams: 100,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_chapati',
        name: 'Chapati (Roti)',
        calories: 297,
        protein: 9.5,
        carbs: 46.0,
        fat: 8.0,
        servingSizeGrams: 100,
        isVerified: true,
      ),

      // Fruits
      FoodItemModel(
        id: 'global_apple',
        name: 'Apple',
        calories: 52,
        protein: 0.3,
        carbs: 14.0,
        fat: 0.2,
        servingSizeGrams: 100,
        fiber: 2.4,
        sugar: 10.4,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_banana',
        name: 'Banana',
        calories: 89,
        protein: 1.1,
        carbs: 22.8,
        fat: 0.3,
        servingSizeGrams: 100,
        fiber: 2.6,
        sugar: 12.2,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_orange',
        name: 'Orange',
        calories: 47,
        protein: 0.9,
        carbs: 11.8,
        fat: 0.1,
        servingSizeGrams: 100,
        fiber: 2.4,
        sugar: 9.4,
        isVerified: true,
      ),

      // Vegetables
      FoodItemModel(
        id: 'global_tomato',
        name: 'Tomato',
        calories: 18,
        protein: 0.9,
        carbs: 3.9,
        fat: 0.2,
        servingSizeGrams: 100,
        fiber: 1.2,
        sugar: 2.6,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_onion',
        name: 'Onion',
        calories: 40,
        protein: 1.1,
        carbs: 9.3,
        fat: 0.1,
        servingSizeGrams: 100,
        fiber: 1.7,
        sugar: 4.2,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_cucumber',
        name: 'Cucumber',
        calories: 15,
        protein: 0.6,
        carbs: 3.6,
        fat: 0.1,
        servingSizeGrams: 100,
        fiber: 0.5,
        sugar: 1.7,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_broccoli',
        name: 'Broccoli',
        calories: 34,
        protein: 2.8,
        carbs: 6.6,
        fat: 0.4,
        servingSizeGrams: 100,
        fiber: 2.6,
        sugar: 1.7,
        isVerified: true,
      ),

      // Dairy
      FoodItemModel(
        id: 'global_milk_whole',
        name: 'Whole Milk',
        calories: 61,
        protein: 3.2,
        carbs: 4.8,
        fat: 3.3,
        servingSizeGrams: 100,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_curd',
        name: 'Curd (Yogurt)',
        calories: 98,
        protein: 3.5,
        carbs: 3.4,
        fat: 4.3,
        servingSizeGrams: 100,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_greek_yogurt',
        name: 'Greek Yogurt (Non-fat)',
        calories: 59,
        protein: 10.2,
        carbs: 3.6,
        fat: 0.4,
        servingSizeGrams: 100,
        isVerified: true,
      ),

      // Nuts
      FoodItemModel(
        id: 'global_almonds',
        name: 'Almonds',
        calories: 579,
        protein: 21.2,
        carbs: 21.6,
        fat: 49.9,
        servingSizeGrams: 100,
        fiber: 12.5,
        sugar: 4.4,
        isVerified: true,
      ),
      FoodItemModel(
        id: 'global_peanuts',
        name: 'Peanuts (Raw)',
        calories: 567,
        protein: 25.8,
        carbs: 16.1,
        fat: 49.2,
        servingSizeGrams: 100,
        fiber: 8.5,
        sugar: 4.7,
        isVerified: true,
      ),
    ];

    for (final food in foods) {
      final docRef = collection.doc(food.id);
      final data = food.toJson();
      data['searchName'] = food.name.toLowerCase();
      batch.set(docRef, data);
    }

    await batch.commit();
    } catch (e) {
      print('Food database seed error: $e');
    }
  }
}

final foodDatabaseRepositoryProvider = Provider<FoodDatabaseRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final firestore = FirebaseFirestore.instance;
  return FoodDatabaseRepository(firestoreService, firestore);
});
