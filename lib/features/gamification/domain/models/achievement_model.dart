import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement_model.freezed.dart';
part 'achievement_model.g.dart';

enum BadgeRarity {
  common,
  rare,
  epic,
  legendary,
}

enum AchievementCategory {
  weight,
  nutrition,
  fasting,
  progressPhotos,
  aiCoach,
  consistency,
  milestones,
}

@freezed
class AchievementModel with _$AchievementModel {
  const factory AchievementModel({
    required String id,
    required String title,
    required String description,
    required AchievementCategory category,
    required BadgeRarity rarity,
    required int xpReward,
    @Default(false) bool isUnlocked,
    DateTime? unlockedAt,
    @Default(0) int currentProgress,
    @Default(1) int targetProgress,
  }) = _AchievementModel;

  factory AchievementModel.fromJson(Map<String, dynamic> json) =>
      _$AchievementModelFromJson(json);
}
