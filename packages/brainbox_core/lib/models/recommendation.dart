import 'package:freezed_annotation/freezed_annotation.dart';

part 'recommendation.freezed.dart';
part 'recommendation.g.dart';

enum RecommendationType { practice, revise, watch, reassess }

/// A suggested next step for the student.
///
// TODO(udith): check these fields against the backend OpenAPI /docs.
@freezed
abstract class Recommendation with _$Recommendation {
  const factory Recommendation({
    required String id,
    required String title,
    @Default('') String reason, // why we recommend it
    @Default(RecommendationType.practice) RecommendationType type,
    String? targetId, // topic / question set / resource id
  }) = _Recommendation;

  factory Recommendation.fromJson(Map<String, dynamic> json) =>
      _$RecommendationFromJson(json);
}
