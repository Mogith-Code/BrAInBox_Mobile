import 'package:brainbox_core/brainbox_core.dart' show Visual;
import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart'
    show AiJob, AiJobStatus, Visual, VisualKind, VisualLabel;

part 'visuals_models.freezed.dart';
part 'visuals_models.g.dart';

/// `GET /topics/{topic_id}/visuals`: the topic header and its visuals.
@freezed
abstract class TopicVisuals with _$TopicVisuals {
  const factory TopicVisuals({
    required String topicId,
    required String topicTitle,
    String? unitCode, // "6" (show it with Formatters.unitLabel)
    String? unitTitle, // "Genetics"
    @Default([]) List<Visual> visuals,
  }) = _TopicVisuals;

  factory TopicVisuals.fromJson(Map<String, dynamic> json) =>
      _$TopicVisualsFromJson(json);
}

/// The chips above the diagram grid (Figma B8).
enum VisualFilter {
  all('All'),
  verified('Verified'),
  aiGenerated('AI-generated'),
  labelled('Labelled');

  const VisualFilter(this.label);

  final String label;

  bool matches(Visual v) => switch (this) {
    all => true,
    verified => v.isVerified,
    aiGenerated => v.isAiGenerated,
    labelled => v.hasLabels,
  };
}

/// "Process flow / Structure / Comparison" on Generate a visual (Figma B10).
/// The backend uses it as a hint when it picks the kind of visual.
enum VisualType {
  @JsonValue('process')
  process('Process flow'),
  @JsonValue('structure')
  structure('Structure'),
  @JsonValue('comparison')
  comparison('Comparison');

  const VisualType(this.label);

  final String label;
}

/// The three style cards on Generate a visual (Figma B10).
enum VisualStyle {
  @JsonValue('flat_colour')
  flatColour('Flat colour'),
  @JsonValue('textbook_line')
  textbookLine('Textbook line'),
  @JsonValue('cross_section')
  crossSection('Cross section');

  const VisualStyle(this.label);

  final String label;
}

/// Body of `POST /visuals/generate`.
@freezed
abstract class GenerateVisualRequest with _$GenerateVisualRequest {
  const factory GenerateVisualRequest({
    required String prompt,
    required VisualType visualType,
    required VisualStyle style,
    String? topicId,
  }) = _GenerateVisualRequest;

  factory GenerateVisualRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateVisualRequestFromJson(json);
}

/// Reasons on the "Report inaccuracy" sheet (backend `VisualReportReason`).
enum VisualReportReason {
  @JsonValue('wrong_label')
  wrongLabel('A label is wrong'),
  @JsonValue('inaccurate')
  inaccurate('The biology is wrong'),
  @JsonValue('unclear')
  unclear("It's hard to understand"),
  @JsonValue('offensive')
  offensive("It's offensive"),
  @JsonValue('other')
  other('Something else');

  const VisualReportReason(this.label);

  final String label;

  /// The value the backend expects (`wrong_label`, ...).
  String get apiValue => switch (this) {
    wrongLabel => 'wrong_label',
    inaccurate => 'inaccurate',
    unclear => 'unclear',
    offensive => 'offensive',
    other => 'other',
  };
}
