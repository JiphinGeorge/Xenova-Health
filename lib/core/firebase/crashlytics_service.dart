import 'dart:isolate';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Isolated Firebase Crashlytics service.
///
/// Handles crash reporting, error logging, and user identification.
class CrashlyticsService {
  CrashlyticsService({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  /// Initializes Crashlytics error handlers.
  ///
  /// Should be called early in app startup after Firebase.initializeApp().
  void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = _crashlytics.recordFlutterFatalError;

    // Catch errors outside of Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    // Catch errors in isolates
    Isolate.current.addErrorListener(
      RawReceivePort((dynamic pair) async {
        final errorAndStacktrace = pair as List<dynamic>;
        await _crashlytics.recordError(
          errorAndStacktrace.first,
          errorAndStacktrace.last as StackTrace?,
          fatal: true,
        );
      }).sendPort,
    );
  }

  /// Records a non-fatal error.
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason ?? 'Non-fatal error',
      fatal: fatal,
    );
  }

  /// Sets the user identifier for crash reports.
  Future<void> setUserId(String id) async {
    await _crashlytics.setUserIdentifier(id);
  }

  /// Logs a message that will appear in crash reports.
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  /// Sets a custom key-value pair for crash reports.
  Future<void> setCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// Enables or disables crash collection.
  Future<void> setCrashlyticsCollectionEnabled({required bool enabled}) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }
}
