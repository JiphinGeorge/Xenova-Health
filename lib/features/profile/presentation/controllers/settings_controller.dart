import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/enums/enums.dart';
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
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        state = SettingsState.fromJson(decoded);
        return;
      } catch (_) {
        // Fallback to default state
      }
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
  }

  Future<void> toggleMealReminder(bool enabled) async {
    await _saveSettings(state.copyWith(mealReminderEnabled: enabled));
  }

  Future<void> toggleFastingReminder(bool enabled) async {
    await _saveSettings(state.copyWith(fastingReminderEnabled: enabled));
  }

  Future<void> toggleWeeklySummaryEnabled(bool enabled) async {
    await _saveSettings(state.copyWith(weeklySummaryEnabled: enabled));
  }

  Future<void> updateWeightReminderTime(TimeOfDay time) async {
    await _saveSettings(state.copyWith(weightReminderTime: time));
  }

  Future<void> updateMealReminderTime(TimeOfDay time) async {
    await _saveSettings(state.copyWith(mealReminderTime: time));
  }

  Future<void> updateFastingReminderTime(TimeOfDay time) async {
    await _saveSettings(state.copyWith(fastingReminderTime: time));
  }

  Future<void> updateWeeklySummaryTime(TimeOfDay time) async {
    await _saveSettings(state.copyWith(weeklySummaryTime: time));
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
