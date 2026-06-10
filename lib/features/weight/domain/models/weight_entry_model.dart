import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/enums/enums.dart';

part 'weight_entry_model.freezed.dart';
part 'weight_entry_model.g.dart';

/// Represents a single weight logging entry.
@freezed
class WeightEntryModel with _$WeightEntryModel {
  const factory WeightEntryModel({
    required String id,
    required String userId,
    required double weight,
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(WeightEntrySource.manual) WeightEntrySource source,
    String? note,
    double? bodyFatPercentage,
    double? muscleMass,
    double? visceralFat,
  }) = _WeightEntryModel;

  factory WeightEntryModel.fromJson(Map<String, dynamic> json) =>
      _$WeightEntryModelFromJson(json);
}
