import 'package:freezed_annotation/freezed_annotation.dart';

part 'topic.freezed.dart';
part 'topic.g.dart';

/// A topic inside a [Unit].
///
// TODO(keshomigha): check these fields against the backend OpenAPI /docs.
@freezed
abstract class Topic with _$Topic {
  const factory Topic({
    required String id,
    required String unitId,
    required String title,
    @Default(0) int order,
    double? mastery, // 0.0 - 1.0 for the signed-in student, if known
  }) = _Topic;

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
}
