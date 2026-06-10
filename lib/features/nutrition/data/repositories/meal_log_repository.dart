import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/meal_log_model.dart';

class MealLogRepository {
  MealLogRepository(this._firestoreService, this._firestore);

  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore;

  String _mealLogsPath(String userId) => 'users/$userId/meal_logs';

  /// Watches all meal logs for a given user on a specific date.
  Stream<List<MealLogModel>> watchMealLogsForDate(
    String userId,
    DateTime date,
  ) {
    // We filter by date. Assuming date is stored at 00:00:00 or we just query by day bounds.
    // Since our date is DateTime but usually has time component, it's safer to query bounds.
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_mealLogsPath(userId))
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MealLogModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Adds a new meal log.
  Future<void> addMealLog(MealLogModel mealLog) async {
    await _firestoreService.setDocument(
      path: '${_mealLogsPath(mealLog.userId)}/${mealLog.id}',
      data: mealLog.toJson(),
    );
  }

  /// Deletes a meal log.
  Future<void> deleteMealLog(String userId, String mealId) async {
    await _firestoreService.deleteDocument('${_mealLogsPath(userId)}/$mealId');
  }
}

final mealLogRepositoryProvider = Provider<MealLogRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final firestore = FirebaseFirestore.instance;
  return MealLogRepository(firestoreService, firestore);
});
