import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/enums/enums.dart';

part 'settings_state.freezed.dart';
part 'settings_state.g.dart';

class TimeOfDayConverter implements JsonConverter<TimeOfDay, Map<String, dynamic>> {
  const TimeOfDayConverter();

  @override
  TimeOfDay fromJson(Map<String, dynamic> json) {
    return TimeOfDay(
      hour: json['hour'] as int? ?? 8,
      minute: json['minute'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson(TimeOfDay object) {
    return {
      'hour': object.hour,
      'minute': object.minute,
    };
  }
}

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default('system') String themeMode,
    @Default(true) bool weightReminderEnabled,
    @Default(true) bool mealReminderEnabled,
    @Default(true) bool fastingReminderEnabled,
    @Default(true) bool weeklySummaryEnabled,
    @TimeOfDayConverter() @Default(TimeOfDay(hour: 8, minute: 0)) TimeOfDay weightReminderTime,
    @TimeOfDayConverter() @Default(TimeOfDay(hour: 12, minute: 0)) TimeOfDay mealReminderTime,
    @TimeOfDayConverter() @Default(TimeOfDay(hour: 20, minute: 0)) TimeOfDay fastingReminderTime,
    @TimeOfDayConverter() @Default(TimeOfDay(hour: 9, minute: 0)) TimeOfDay weeklySummaryTime,
    @Default(true) bool weeklySummaryToggle,
    @Default(CoachTone.supportive) CoachTone coachTone,
    @Default(1) int schemaVersion,
  }) = _SettingsState;

  factory SettingsState.fromJson(Map<String, dynamic> json) =>
      _$SettingsStateFromJson(json);
}
