import 'package:firebase_analytics/firebase_analytics.dart';

/// Isolated Firebase Analytics service.
///
/// Tracks custom events, user properties, and screen views.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// Gets the analytics observer for GoRouter integration.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Logs a custom event.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Sets a user property.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Sets the current user ID.
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
  }

  /// Logs a screen view.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Logs app open event.
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  /// Logs sign up event.
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// Logs login event.
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }
}
