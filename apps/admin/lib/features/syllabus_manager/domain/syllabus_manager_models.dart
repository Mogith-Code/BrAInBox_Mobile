import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Unit, Topic, Concept;

part 'syllabus_manager_models.freezed.dart';
part 'syllabus_manager_models.g.dart';

/// Placeholder model for the SyllabusManager feature.
///
// TODO(keshomigha): replace these fields with the response of `GET /admin/units`
// (see the backend OpenAPI /docs), or delete this class and use the shared
// models from brainbox_core. Run `melos run gen` after editing.
@freezed
abstract class SyllabusManagerSummary with _$SyllabusManagerSummary {
  const factory SyllabusManagerSummary({
    required String title,
    @Default('') String message,
  }) = _SyllabusManagerSummary;

  factory SyllabusManagerSummary.fromJson(Map<String, dynamic> json) =>
      _$SyllabusManagerSummaryFromJson(json);
}
