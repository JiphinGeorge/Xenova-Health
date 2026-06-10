import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';

/// Offline-first sync service skeleton.
///
/// Manages a queue of pending changes and syncs them to Firestore
/// when connectivity is restored. Uses last-write-wins conflict resolution.
class SyncService {
  SyncService({required this.connectivityService});

  final ConnectivityService connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  /// Whether a sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Initializes the sync service and listens for connectivity changes.
  void initialize() {
    _connectivitySubscription = connectivityService.onConnectivityChanged
        .listen((isConnected) {
          if (isConnected && !_isSyncing) {
            syncAll();
          }
        });
  }

  /// Triggers a full sync of all pending changes.
  Future<void> syncAll() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      final isOnline = await connectivityService.isConnected;
      if (!isOnline) return;

      // Sync operations will be implemented by feature modules
      // Each module registers its sync handler
      for (final handler in _syncHandlers) {
        try {
          await handler();
        } on Exception catch (e) {
          debugPrint('Sync handler failed: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// List of registered sync handlers from feature modules.
  final List<Future<void> Function()> _syncHandlers = [];

  /// Registers a sync handler from a feature module.
  void registerSyncHandler(Future<void> Function() handler) {
    _syncHandlers.add(handler);
  }

  /// Disposes the connectivity listener.
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
