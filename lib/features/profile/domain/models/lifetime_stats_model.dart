import 'package:freezed_annotation/freezed_annotation.dart';

part 'lifetime_stats_model.freezed.dart';
part 'lifetime_stats_model.g.dart';

@freezed
class LifetimeStatsModel with _$LifetimeStatsModel {
  const factory LifetimeStatsModel({
    @Default(0) int totalWeightEntries,
    @Default(0) int totalMealsLogged,
    @Default(0) int totalFastsCompleted,
    @Default(0) int totalProgressPhotos,
    @Default(0) int totalAIChats,
    @Default(0) int totalDaysTracked,
    DateTime? lastTrackedDay,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LifetimeStatsModel;

  factory LifetimeStatsModel.fromJson(Map<String, dynamic> json) =>
      _$LifetimeStatsModelFromJson(json);
}
