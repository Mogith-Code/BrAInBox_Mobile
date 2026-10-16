import 'package:freezed_annotation/freezed_annotation.dart';

part 'knowledge_base_models.freezed.dart';
part 'knowledge_base_models.g.dart';

/// Placeholder model for the KnowledgeBase feature.
///
// TODO(keshomigha): replace these fields with the response of `GET /admin/model-answers`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class KnowledgeBaseSummary with _$KnowledgeBaseSummary {
  const factory KnowledgeBaseSummary({
    required String title,
    @Default('') String message,
  }) = _KnowledgeBaseSummary;

  factory KnowledgeBaseSummary.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeBaseSummaryFromJson(json);
}
