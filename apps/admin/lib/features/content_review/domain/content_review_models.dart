import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
export 'package:brainbox_core/brainbox_core.dart' show Note, Visual;

part 'content_review_models.freezed.dart';
part 'content_review_models.g.dart';

/// The tabs of the Content library.
enum ContentType {
  @JsonValue('note')
  note('Notes'),
  @JsonValue('short_note')
  shortNote('Short notes'),
  @JsonValue('diagram')
  diagram('Diagrams');

  const ContentType(this.label);

  final String label;

  String get apiValue => switch (this) {
    note => 'note',
    shortNote => 'short_note',
    diagram => 'diagram',
  };

  /// Singular, for the table ("Short notes" -> "Short notes" stays plural
  /// in the design, so only Notes / Diagram change).
  String get rowLabel => switch (this) {
    note => 'Notes',
    shortNote => 'Short notes',
    diagram => 'Diagram',
  };
}

/// One row of the Content library (`GET /admin/content`).
@freezed
abstract class ContentItem with _$ContentItem {
  const factory ContentItem({
    required String id,
    required String title,
    @JsonKey(unknownEnumValue: ContentType.note)
    @Default(ContentType.note)
    ContentType type,
    String? syllabusCode, // "5.4"
    int? unitNumber,
    @Default('draft') String status, // ContentStatus value
    @Default(false) bool isAiGenerated,
    String? model, // "Gemini 2.5 Flash"
    String? promptVersion, // "notes/generate.v3"
    String? bodyMarkdown, // notes / short notes
    String? imageUrl, // diagrams
    String? autoCheck, // a warning from the automatic checks
    DateTime? updatedAt,
  }) = _ContentItem;

  factory ContentItem.fromJson(Map<String, dynamic> json) =>
      _$ContentItemFromJson(json);
}
