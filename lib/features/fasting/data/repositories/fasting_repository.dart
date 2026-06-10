import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/fasting_session_model.dart';

/// Repository for managing Intermittent Fasting sessions in Firestore.
class FastingRepository {
  FastingRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  String _collectionPath(String userId) => 'users/$userId/fasting_sessions';

  /// Streams all fasting sessions ordered by start time descending.
  Stream<List<FastingSessionModel>> watchFastingHistory(String userId) {
    return _firestoreService
        .streamCollection(
          path: _collectionPath(userId),
          orderBy: 'startTime',
          descending: true,
        )
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FastingSessionModel.fromJson(doc.data()))
              .toList();
        });
  }

  /// Saves a new fasting session (e.g., starts a fast).
  Future<void> saveFastingSession(FastingSessionModel session) async {
    await _firestoreService.setDocument(
      path: '${_collectionPath(session.userId)}/${session.id}',
      data: session.toJson(),
    );
  }

  /// Updates an existing fasting session (e.g., ends a fast).
  Future<void> updateFastingSession(FastingSessionModel session) async {
    await _firestoreService.updateDocument(
      path: '${_collectionPath(session.userId)}/${session.id}',
      data: session.toJson(),
    );
  }

  /// Deletes a fasting session.
  Future<void> deleteFastingSession(String userId, String sessionId) async {
    await _firestoreService.deleteDocument(
      '${_collectionPath(userId)}/$sessionId',
    );
  }

  /// Gets the fasting sessions for a given date range.
  Future<List<FastingSessionModel>> getFastingSessionsForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startString = startDate.toIso8601String();
    final endString = endDate.toIso8601String();

    final snapshot = await FirebaseFirestore.instance
        .collection('users/$userId/fasting_sessions')
        .where('startTime', isGreaterThanOrEqualTo: startString)
        .where('startTime', isLessThanOrEqualTo: endString)
        .get();

    return snapshot.docs
        .map((doc) => FastingSessionModel.fromJson(doc.data()))
        .toList();
  }
}

/// Provider for [FastingRepository].
final fastingRepositoryProvider = Provider<FastingRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return FastingRepository(firestoreService);
});
