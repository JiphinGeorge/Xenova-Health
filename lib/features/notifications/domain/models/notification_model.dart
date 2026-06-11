import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

enum NotificationCategory {
  @JsonValue('weight')
  weight,
  @JsonValue('nutrition')
  nutrition,
  @JsonValue('fasting')
  fasting,
  @JsonValue('aiCoach')
  aiCoach,
  @JsonValue('achievement')
  achievement,
  @JsonValue('system')
  system,
}

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String title,
    required String body,
    required NotificationCategory category,
    @Default(false) bool isRead,
    required DateTime timestamp,
    String? relatedEntityId,
    String? routePath,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
