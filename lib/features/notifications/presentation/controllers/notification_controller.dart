import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification_model.dart';

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, List<NotificationModel>>(
  NotificationController.new,
);

class NotificationController extends AsyncNotifier<List<NotificationModel>> {
  @override
  FutureOr<List<NotificationModel>> build() {
    final repo = ref.watch(notificationRepositoryProvider);
    
    // Subscribe to the stream and update state when new data arrives
    final sub = repo.streamNotifications().listen((notifications) {
      state = AsyncValue.data(notifications);
    });
    
    ref.onDispose(() => sub.cancel());
    
    // Initial fetch
    return repo.streamNotifications().first;
  }

  int get unreadCount {
    return state.valueOrNull?.where((n) => !n.isRead).length ?? 0;
  }

  Future<void> markAsRead(String id) async {
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await ref.read(notificationRepositoryProvider).deleteNotification(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await ref.read(notificationRepositoryProvider).clearAllNotifications();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
