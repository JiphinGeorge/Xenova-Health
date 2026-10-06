import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/fasting_session_model.dart';

/// Repository for managing Intermittent Fasting sessions in Firestore and Hive.
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
          final list = snapshot.docs
              .map((doc) => FastingSessionModel.fromJson(doc.data()))
              .toList();

          // Cache to local Hive box for offline resilience
          try {
            final box = Hive.box<dynamic>(AppConstants.fastingBox);
            for (final session in list) {
              box.put(session.id, session.toJson());
            }
          } catch (_) {}

          return list;
        })
        .handleError((error) {
          // Fallback to local Hive box if Firestore is offline or fails
          try {
            final box = Hive.box<dynamic>(AppConstants.fastingBox);
            final cached = box.values
                .map((e) => FastingSessionModel.fromJson(Map<String, dynamic>.from(e as Map)))
                .where((s) => s.userId == userId)
                .toList();
            cached.sort((a, b) => b.startTime.compareTo(a.startTime));
            return cached;
          } catch (_) {
            return <FastingSessionModel>[];
          }
        });
  }

  /// Saves a new fasting session (e.g., starts a fast).
  Future<void> saveFastingSession(FastingSessionModel session) async {
    // Cache locally immediately
    try {
      final box = Hive.box<dynamic>(AppConstants.fastingBox);
      await box.put(session.id, session.toJson());
    } catch (_) {}

    try {
      await _firestoreService.setDocument(
        path: '${_collectionPath(session.userId)}/${session.id}',
        data: session.toJson(),
      );
    } catch (_) {
      // Offline mode: already stored in Hive
    }
  }

  /// Updates an existing fasting session (e.g., ends a fast).
  Future<void> updateFastingSession(FastingSessionModel session) async {
    // Cache locally immediately
    try {
      final box = Hive.box<dynamic>(AppConstants.fastingBox);
      await box.put(session.id, session.toJson());
    } catch (_) {}

    try {
      await _firestoreService.updateDocument(
        path: '${_collectionPath(session.userId)}/${session.id}',
        data: session.toJson(),
      );
    } catch (_) {
      // Offline mode: already stored in Hive
    }
  }

  /// Deletes a fasting session.
  Future<void> deleteFastingSession(String userId, String sessionId) async {
    try {
      final box = Hive.box<dynamic>(AppConstants.fastingBox);
      await box.delete(sessionId);
    } catch (_) {}

    try {
      await _firestoreService.deleteDocument(
        '${_collectionPath(userId)}/$sessionId',
      );
    } catch (_) {}
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

  /// Gets all fasting sessions once (e.g. for CSV export).
  Future<List<FastingSessionModel>> getSessionsOnce(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(_collectionPath(userId))
        .orderBy('startTime', descending: true)
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
