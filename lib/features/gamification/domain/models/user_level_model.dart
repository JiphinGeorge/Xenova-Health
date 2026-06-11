import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_level_model.freezed.dart';
part 'user_level_model.g.dart';

@freezed
class UserLevelModel with _$UserLevelModel {
  const factory UserLevelModel({
    required String userId,
    @Default(1) int currentLevel,
    @Default(0) int totalXp,
    @Default(100) int xpForNextLevel,
    @Default(0) int currentLoginStreak,
    @Default(0) int longestLoginStreak,
    DateTime? lastLoginDate,
  }) = _UserLevelModel;

  factory UserLevelModel.fromJson(Map<String, dynamic> json) =>
      _$UserLevelModelFromJson(json);
}
