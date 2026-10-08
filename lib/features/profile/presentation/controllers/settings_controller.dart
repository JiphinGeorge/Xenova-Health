import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/models/settings_state.dart';

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._ref) : super(const SettingsState(
    weightReminderTime: TimeOfDay(hour: 8, minute: 0),
    mealReminderTime: TimeOfDay(hour: 12, minute: 0),
    fastingReminderTime: TimeOfDay(hour: 20, minute: 0),
    weeklySummaryTime: TimeOfDay(hour: 9, minute: 0),
  )) {
    _loadSettings();
  }

  final Ref _ref;

  void _loadSettings() {
    final box = _ref.read(hiveServiceProvider).settingsBox;
    final jsonStr = box.get('settings_data') as String?;
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = SettingsState.fromJson(decoded);
        _rescheduleActiveReminders();
        return;
      } catch (_) {
        // Fallback to default state
      }
    }
  }

  void _rescheduleActiveReminders() {
    if (state.weightReminderEnabled) {
      _syncNotificationSchedule(
        enabled: true,
        id: NotificationService.idWeightReminder,
        title: 'Time to Weigh In! ⚖️',
        body: 'Log your morning weight to keep your progress chart accurate.',
        time: state.weightReminderTime,
      );
    }
    if (state.mealReminderEnabled) {
      _syncNotificationSchedule(
        enabled: true,
        id: NotificationService.idMealReminder,
        title: 'Meal Log Reminder 🥗',
        body: "Don't forget to track your meal and calories today!",
        time: state.mealReminderTime,
      );
    }
    if (state.fastingReminderEnabled) {
      _syncNotificationSchedule(
        enabled: true,
        id: NotificationService.idFastingReminder,
        title: 'Fasting Window Reminder ⏱️',
        body: 'Time to check your fasting timer and prepare for your eating window.',
        time: state.fastingReminderTime,
      );
    }
    if (state.weeklySummaryEnabled) {
      _syncNotificationSchedule(
        enabled: true,
        id: NotificationService.idWeeklySummary,
        title: 'Your Weekly Health Summary is Ready! 📊',
        body: 'Check out your weekly stats, fasting milestones, and health score.',
        time: state.weeklySummaryTime,
        isWeekly: true,
      );
    }
  }

  Future<void> _syncNotificationSchedule({
    required bool enabled,
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    bool isWeekly = false,
  }) async {
    final notifications = _ref.read(notificationServiceProvider);
    if (!enabled) {
      await notifications.cancelNotification(id);
      return;
    }

    if (isWeekly) {
      await notifications.scheduleWeeklyNotification(
        id: id,
        title: title,
        body: body,
        dayOfWeek: DateTime.sunday,
        hour: time.hour,
        minute: time.minute,
      );
    } else {
      await notifications.scheduleDailyNotification(
        id: id,
        title: title,
        body: body,
        hour: time.hour,
        minute: time.minute,
      );
    }
  }

  Future<void> _saveSettings(SettingsState newState) async {
    final box = _ref.read(hiveServiceProvider).settingsBox;
    final jsonStr = jsonEncode(newState.toJson());
    await box.put('settings_data', jsonStr);
    state = newState;
  }

  Future<void> updateThemeMode(String mode) async {
    await _saveSettings(state.copyWith(themeMode: mode));
  }

  Future<void> toggleWeightReminder(bool enabled) async {
    await _saveSettings(state.copyWith(weightReminderEnabled: enabled));
    await _syncNotificationSchedule(
      enabled: enabled,
      id: NotificationService.idWeightReminder,
      title: 'Time to Weigh In! ⚖️',
      body: 'Log your morning weight to keep your progress chart accurate.',
      time: state.weightReminderTime,
    );
  }

  Future<void> toggleMealReminder(bool enabled) async {
    await _saveSettings(state.copyWith(mealReminderEnabled: enabled));
    await _syncNotificationSchedule(
      enabled: enabled,
      id: NotificationService.idMealReminder,
      title: 'Meal Log Reminder 🥗',
      body: "Don't forget to track your meal and calories today!",
      time: state.mealReminderTime,
    );
  }

  Future<void> toggleFastingReminder(bool enabled) async {
    await _saveSettings(state.copyWith(fastingReminderEnabled: enabled));
    await _syncNotificationSchedule(
      enabled: enabled,
      id: NotificationService.idFastingReminder,
      title: 'Fasting Window Reminder ⏱️',
      body: 'Time to check your fasting timer and prepare for your eating window.',
      time: state.fastingReminderTime,
    );
  }

  Future<void> toggleWeeklySummaryEnabled(bool enabled) async {
    await _saveSettings(state.copyWith(weeklySummaryEnabled: enabled));
    await _syncNotificationSchedule(
      enabled: enabled,
      id: NotificationService.idWeeklySummary,
      title: 'Your Weekly Health Summary is Ready! 📊',
      body: 'Check out your weekly stats, fasting milestones, and health score.',
      time: state.weeklySummaryTime,
      isWeekly: true,
    );
  }

  Future<void> updateWeightReminderTime(TimeOfDay time) async {
    await _saveSettings(state.copyWith(weightReminderTime: time));
    if (state.weightReminderEnabled) {
      await _syncNotificationSchedule(
        enabled: true,
        id: NotificationService.idWeightReminder,
        title: 'Time to Weigh In! ⚖️',
        body: 'Log your morning weight to keep your progress chart accurate.',
        time: time,
      );
    }
  }

  Future<void> updateMealReminderTime(TimeOfDay time) async {
    await _saveSettings(state.copyWith(mealReminderTime: time));
    if (state.mealReminderEnabled) {
      await _syncNotificationSchedule(
        enabled: true,
        id: NotificationService.idMealReminder,
        title: 'Meal Log Reminder 🥗',
        body: "Don't forget to track your meal and calories today!",
        time: time,
      );
    }
  }

  Future<void> updateFastingReminderTime(TimeOfDay time) async {
    await _saveSettings(state.copyWith(fastingReminderTime: time));
    if (state.fastingReminderEnabled) {
      await _syncNotificationSchedule(
        enabled: true,
        id: NotificationService.idFastingReminder,
        title: 'Fasting Window Reminder ⏱️',
        body: 'Time to check your fasting timer and prepare for your eating window.',
        time: time,
      );
    }
  }

  Future<void> updateWeeklySummaryTime(TimeOfDay time) async {
    await _saveSettings(state.copyWith(weeklySummaryTime: time));
    if (state.weeklySummaryEnabled) {
      await _syncNotificationSchedule(
        enabled: true,
        id: NotificationService.idWeeklySummary,
        title: 'Your Weekly Health Summary is Ready! 📊',
        body: 'Check out your weekly stats, fasting milestones, and health score.',
        time: time,
        isWeekly: true,
      );
    }
  }

  Future<void> toggleWeeklySummary(bool value) async {
    await _saveSettings(state.copyWith(weeklySummaryToggle: value));
  }

  Future<void> updateCoachTone(CoachTone tone) async {
    await _saveSettings(state.copyWith(coachTone: tone));
  }

  Future<void> clearLocalCache() async {
    // Clear Hive local caches
    await _ref.read(hiveServiceProvider).clearAll();
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(ref);
});
