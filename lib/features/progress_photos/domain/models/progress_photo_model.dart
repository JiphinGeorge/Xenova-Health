import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_photo_model.freezed.dart';
part 'progress_photo_model.g.dart';

/// Represents a progress photo entry with associated health metrics.
@freezed
class ProgressPhotoModel with _$ProgressPhotoModel {
  const factory ProgressPhotoModel({
    required String id,
    required String userId,
    required String photoUrl,
    required double weightAtTime,
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? thumbnailUrl,
    String? note,
    int? imageWidth,
    int? imageHeight,
    double? bodyFatPercentage,
    double? waistMeasurement,
  }) = _ProgressPhotoModel;

  factory ProgressPhotoModel.fromJson(Map<String, dynamic> json) =>
      _$ProgressPhotoModelFromJson(json);
}
