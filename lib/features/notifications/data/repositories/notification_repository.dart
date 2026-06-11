import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final userAsync = ref.watch(authControllerProvider);
  final uid = userAsync.value?.uid;
  if (uid == null) {
    throw Exception('User not authenticated');
  }
  return NotificationRepository(FirebaseFirestore.instance, uid);
});

class NotificationRepository {
  NotificationRepository(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(_uid).collection('notifications');

  Stream<List<NotificationModel>> streamNotifications() {
    return _collection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Handle Firestore Timestamp parsing manually for Freezed if needed,
        // or ensure you use a converter. Assuming timestamp is handled correctly.
        // We convert Timestamp to string format expected by Freezed (ISO 8601) or Timestamp Converter.
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }

        return NotificationModel.fromJson(data);
      }).toList();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _collection.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    // We only want to update unread notifications.
    // Fetch top 100 or unread from Firestore. Let's just update locally fetched unread ones via the controller,
    // or run a batch update.
    final snapshot = await _collection.where('isRead', isEqualTo: false).limit(100).get();
    
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _collection.doc(notificationId).delete();
  }

  Future<void> clearAllNotifications() async {
    // Delete all notifications in batches
    final snapshot = await _collection.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
  
  // Method to create a notification (used by other services)
  Future<void> createNotification(NotificationModel notification) async {
    final docRef = _collection.doc();
    final data = notification.copyWith(id: docRef.id).toJson();
    // Convert DateTime back to Timestamp
    data['timestamp'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }
}
