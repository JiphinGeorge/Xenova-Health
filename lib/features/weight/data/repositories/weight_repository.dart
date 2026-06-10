import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../domain/models/weight_entry_model.dart';

/// Repository for managing Weight Entries in Firestore.
/// Relies on Firestore's native offline persistence for offline support.
class WeightRepository {
  WeightRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  String _collectionPath(String userId) => 'users/$userId/weight_entries';

  /// Adds a new weight entry.
  Future<void> addEntry(WeightEntryModel entry) async {
    await _firestoreService.setDocument(
      path: '${_collectionPath(entry.userId)}/${entry.id}',
      data: entry.toJson(),
    );
  }

  /// Updates an existing weight entry.
  Future<void> updateEntry(WeightEntryModel entry) async {
    await _firestoreService.updateDocument(
      path: '${_collectionPath(entry.userId)}/${entry.id}',
      data: entry.toJson(),
    );
  }

  /// Deletes a weight entry.
  Future<void> deleteEntry(String userId, String entryId) async {
    await _firestoreService.deleteDocument(
      '${_collectionPath(userId)}/$entryId',
    );
  }

  /// Streams all weight entries for a given user, ordered by date descending.
  Stream<List<WeightEntryModel>> watchEntries(String userId) {
    return _firestoreService
        .streamCollection(
          path: _collectionPath(userId),
          orderBy: 'date',
          descending: true,
        )
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return WeightEntryModel.fromJson(doc.data());
          }).toList();
        });
  }

  /// Fetches all weight entries once (useful for CSV export).
  Future<List<WeightEntryModel>> getWeightEntries(String userId) async {
    final snapshot = await _firestoreService.getCollection(
      path: _collectionPath(userId),
      orderBy: 'date',
      descending: true,
    );
    return snapshot.docs
        .map((doc) => WeightEntryModel.fromJson(doc.data()))
        .toList();
  }

  /// Gets the weight entries for a given date range.
  Future<List<WeightEntryModel>> getWeightEntriesForRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startString = startDate.toIso8601String();
    final endString = endDate.toIso8601String();

    final snapshot = await FirebaseFirestore.instance
        .collection('users/$userId/weight_entries')
        .where('date', isGreaterThanOrEqualTo: startString)
        .where('date', isLessThanOrEqualTo: endString)
        .get();

    return snapshot.docs
        .map((doc) => WeightEntryModel.fromJson(doc.data()))
        .toList();
  }
}

/// Provider for [WeightRepository].
final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return WeightRepository(firestoreService);
});
