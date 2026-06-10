import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_score_model.freezed.dart';
part 'health_score_model.g.dart';

@freezed
class HealthScoreModel with _$HealthScoreModel {
  const factory HealthScoreModel({
    @Default(0) double nutritionScore,
    @Default(0) double fastingScore,
    @Default(0) double weightConsistencyScore,
    @Default(0) double waterScore,
    @Default(0) double overallHealthScore,
  }) = _HealthScoreModel;

  factory HealthScoreModel.fromJson(Map<String, dynamic> json) =>
      _$HealthScoreModelFromJson(json);
}
