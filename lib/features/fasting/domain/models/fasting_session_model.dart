import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/enums/enums.dart';

part 'fasting_session_model.freezed.dart';
part 'fasting_session_model.g.dart';

@freezed
class FastingSessionModel with _$FastingSessionModel {
  const factory FastingSessionModel({
    required String id,
    required String userId,
    required FastingPlan planType,
    required DateTime startTime,
    DateTime? endTime,
    required double targetDurationHours,
    @Default(false) bool completed,
    int? durationMinutes,
    double? plannedDurationHours,
    double? actualDurationHours,
    double? completionPercentage,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FastingSessionModel;

  factory FastingSessionModel.fromJson(Map<String, dynamic> json) =>
      _$FastingSessionModelFromJson(json);
}
