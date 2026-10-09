import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/enums/activity_level.dart';
import '../../../../core/enums/diet_type.dart';
import '../../../../core/enums/fasting_plan.dart';
import '../../../../core/enums/gender.dart';
import '../../../../core/enums/primary_goal.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Represents a user profile in Xenova Health.
///
/// Contains identity information from Firebase Auth and personalized
/// health metrics from the onboarding process.
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String email,
    required DateTime createdAt,
    String? displayName,
    String? photoUrl,

    // ─── Onboarding Baseline Metrics ───
    int? age,
    Gender? gender,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
    PrimaryGoal? primaryGoal,

    // ─── Preferences ───
    DietType? preferredDiet,
    FastingPlan? fastingPlan,

    /// Stored in milliliters for precision
    int? dailyWaterGoalMl,

    @Default(false) bool isOnboardingComplete,
  }) = _UserModel;

  /// Creates a [UserModel] from a JSON object (Firestore document).
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

/// Extension providing dynamic calculation of user goals from profile onboarding data.
extension UserModelWaterGoal on UserModel {
  /// Dynamically computes or retrieves the user's daily water goal in ml.
  /// Prioritizes explicit [dailyWaterGoalMl], otherwise calculates based on
  /// first-time onboarding metrics (body weight & activity level).
  int get effectiveWaterGoalMl {
    if (dailyWaterGoalMl != null && dailyWaterGoalMl! > 0) {
      return dailyWaterGoalMl!;
    }
    if (currentWeightKg != null && currentWeightKg! > 0) {
      int base = (currentWeightKg! * 35).round();
      if (activityLevel == ActivityLevel.veryActive ||
          activityLevel == ActivityLevel.extraActive) {
        base += 500;
      } else if (activityLevel == ActivityLevel.moderatelyActive) {
        base += 250;
      }
      return ((base / 50).round() * 50).clamp(1500, 5000);
    }
    return 2500;
  }
}
