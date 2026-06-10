import 'package:cloud_firestore/cloud_firestore.dart';

/// Isolated Firestore service for database operations.
///
/// Provides typed CRUD operations with path-based access,
/// keeping Firestore SDK details out of the repository layer.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Gets a reference to a document.
  DocumentReference<Map<String, dynamic>> doc(String path) =>
      _firestore.doc(path);

  /// Gets a reference to a collection.
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _firestore.collection(path);

  /// Creates or overwrites a document.
  Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    await _firestore.doc(path).set(data, SetOptions(merge: merge));
  }

  /// Updates fields in a document (document must exist).
  Future<void> updateDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.doc(path).update(data);
  }

  /// Gets a single document.
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String path,
  ) async {
    return _firestore.doc(path).get();
  }

  /// Deletes a document.
  Future<void> deleteDocument(String path) async {
    await _firestore.doc(path).delete();
  }

  /// Gets all documents in a collection with optional ordering and filtering.
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection({
    required String path,
    String? orderBy,
    bool descending = false,
    int? limit,
    List<List<dynamic>>? whereConditions,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(path);

    if (whereConditions != null) {
      for (final condition in whereConditions) {
        if (condition.length == 3) {
          query = query.where(
            condition[0] as String,
            isEqualTo: condition[1] == '==' ? condition[2] : null,
            isGreaterThan: condition[1] == '>' ? condition[2] : null,
            isGreaterThanOrEqualTo: condition[1] == '>=' ? condition[2] : null,
            isLessThan: condition[1] == '<' ? condition[2] : null,
            isLessThanOrEqualTo: condition[1] == '<=' ? condition[2] : null,
          );
        }
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.get();
  }

  /// Streams a single document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument(String path) {
    return _firestore.doc(path).snapshots();
  }

  /// Streams a collection with optional ordering.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String path,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(path);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  /// Performs a batch write operation.
  Future<void> batchWrite(
    Future<void> Function(WriteBatch batch) operations,
  ) async {
    final batch = _firestore.batch();
    await operations(batch);
    await batch.commit();
  }

  /// Performs a transaction.
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) handler,
  ) async {
    return _firestore.runTransaction(handler);
  }

  /// Returns a server timestamp.
  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Adds a document to a collection with auto-generated ID.
  Future<DocumentReference<Map<String, dynamic>>> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    return _firestore.collection(collectionPath).add(data);
  }
}
