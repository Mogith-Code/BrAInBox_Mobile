import 'package:freezed_annotation/freezed_annotation.dart';

part 'concept.freezed.dart';
part 'concept.g.dart';

/// A single concept inside a [Topic] (smallest syllabus item).
///
// TODO(keshomigha): check these fields against the backend OpenAPI /docs.
@freezed
abstract class Concept with _$Concept {
  const factory Concept({
    required String id,
    required String topicId,
    required String title,
    String? summary,
  }) = _Concept;

  factory Concept.fromJson(Map<String, dynamic> json) =>
      _$ConceptFromJson(json);
}
