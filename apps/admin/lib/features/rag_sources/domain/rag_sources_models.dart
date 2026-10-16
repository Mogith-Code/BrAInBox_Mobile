import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show AiJob;

part 'rag_sources_models.freezed.dart';
part 'rag_sources_models.g.dart';

/// Placeholder model for the RagSources feature.
///
// TODO(samni): replace these fields with the response of `GET /admin/rag/sources`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class RagSourcesSummary with _$RagSourcesSummary {
  const factory RagSourcesSummary({
    required String title,
    @Default('') String message,
  }) = _RagSourcesSummary;

  factory RagSourcesSummary.fromJson(Map<String, dynamic> json) =>
      _$RagSourcesSummaryFromJson(json);
}
