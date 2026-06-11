import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logWeightLogged({required double weight}) async {
    await _analytics.logEvent(
      name: 'weight_logged',
      parameters: {'weight': weight},
    );
  }

  Future<void> logMealLogged({required String mealType, required int calories}) async {
    await _analytics.logEvent(
      name: 'meal_logged',
      parameters: {
        'meal_type': mealType,
        'calories': calories,
      },
    );
  }

  Future<void> logFastStarted({required String duration}) async {
    await _analytics.logEvent(
      name: 'fast_started',
      parameters: {'duration': duration},
    );
  }

  Future<void> logFastCompleted({required int durationMinutes}) async {
    await _analytics.logEvent(
      name: 'fast_completed',
      parameters: {'duration_minutes': durationMinutes},
    );
  }

  Future<void> logPhotoUploaded() async {
    await _analytics.logEvent(name: 'photo_uploaded');
  }

  Future<void> logAiChatStarted() async {
    await _analytics.logEvent(name: 'ai_chat_started');
  }

  Future<void> logReportExported({required String format}) async {
    await _analytics.logEvent(
      name: 'report_exported',
      parameters: {'format': format},
    );
  }

  Future<void> logAchievementUnlocked({required String achievementId}) async {
    await _analytics.logUnlockAchievement(id: achievementId);
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
