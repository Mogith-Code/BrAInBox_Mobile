import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
export 'package:brainbox_core/brainbox_core.dart' show Question, McqOption;

part 'question_bank_models.freezed.dart';
part 'question_bank_models.g.dart';

enum QuestionKind {
  mcq('MCQ'),
  structured('Structured'),
  essay('Essay');

  const QuestionKind(this.label);

  final String label;
}

enum Difficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const Difficulty(this.label);

  final String label;
}

/// One row of the question bank (`GET /admin/questions`).
@freezed
abstract class QuestionRow with _$QuestionRow {
  const factory QuestionRow({
    required String id,
    required String code, // "Q-4821"
    required String stem,
    int? unitNumber,
    String? topicTitle, // "Respiration"
    @JsonKey(unknownEnumValue: QuestionKind.mcq)
    @Default(QuestionKind.mcq)
    QuestionKind type,
    @JsonKey(unknownEnumValue: Difficulty.medium)
    @Default(Difficulty.medium)
    Difficulty difficulty,
    int? sourceYear, // past paper year; null + AI = AI-generated
    @Default(false) bool isAiGenerated,
    @Default('draft') String status,
  }) = _QuestionRow;

  factory QuestionRow.fromJson(Map<String, dynamic> json) =>
      _$QuestionRowFromJson(json);
}

@freezed
abstract class QuestionPage with _$QuestionPage {
  const factory QuestionPage({
    @Default([]) List<QuestionRow> items,
    @Default(0) int total,
    @Default(0) int pastPaperPercent, // "41% from past papers"
  }) = _QuestionPage;

  factory QuestionPage.fromJson(Map<String, dynamic> json) =>
      _$QuestionPageFromJson(json);
}

/// The filter buttons above the table.
@freezed
abstract class QuestionFilter with _$QuestionFilter {
  const QuestionFilter._();

  const factory QuestionFilter({
    int? unit,
    QuestionKind? type,
    Difficulty? difficulty,
    String? status,
    @Default(1) int page,
  }) = _QuestionFilter;

  static const pageSize = 10;

  Map<String, dynamic> toQuery() => {
    'unit': ?unit,
    if (type != null) 'type': type!.name,
    if (difficulty != null) 'difficulty': difficulty!.name,
    'status': ?status,
    'page': page,
    'page_size': pageSize,
  };
}

/// What the bulk bar does with the selected rows
/// (`POST /admin/questions/bulk` with `{ids, action}`).
enum BulkAction {
  approve('Approve'),
  markOutdated('Mark outdated'),
  delete('Delete');

  const BulkAction(this.label);

  final String label;

  String get apiValue => switch (this) {
    approve => 'approve',
    markOutdated => 'mark_outdated',
    delete => 'delete',
  };
}

/// One MCQ option in the editor, with the misconception a student who
/// picks it probably has.
@freezed
abstract class OptionDraft with _$OptionDraft {
  const factory OptionDraft({
    required String label, // A..E
    @Default('') String text,
    @Default(false) bool isCorrect,
    String? misconception,
  }) = _OptionDraft;

  factory OptionDraft.fromJson(Map<String, dynamic> json) =>
      _$OptionDraftFromJson(json);
}

/// `GET /admin/questions/{id}` and the body of `PUT /admin/questions/{id}`.
@freezed
abstract class QuestionDetail with _$QuestionDetail {
  const QuestionDetail._();

  const factory QuestionDetail({
    String? id, // null = a new question
    String? code,
    @Default('') String stem,
    @Default(QuestionKind.mcq) QuestionKind type,
    @Default(Difficulty.medium) Difficulty difficulty,
    String? unitId,
    String? topicId,
    String? conceptId,
    @Default('') String explanation,
    @Default('draft') String status,
    @Default(false) bool isAiGenerated,
    @Default([]) List<OptionDraft> options,
  }) = _QuestionDetail;

  factory QuestionDetail.fromJson(Map<String, dynamic> json) =>
      _$QuestionDetailFromJson(json);

  /// A new MCQ with five empty options.
  static QuestionDetail blank() => QuestionDetail(
    options: [for (final l in 'ABCDE'.split('')) OptionDraft(label: l)],
  );

  /// What still blocks "Publish" (empty = ready).
  List<String> get problems => [
    if (stem.trim().isEmpty) 'Write the question stem.',
    if (topicId == null) 'Pick the topic.',
    if (type == QuestionKind.mcq) ...[
      if (options.where((o) => o.isCorrect).length != 1)
        'Mark exactly one correct answer.',
      if (options.any((o) => o.text.trim().isEmpty)) 'Fill in every option.',
      if (options.any(
        (o) => !o.isCorrect && (o.misconception ?? '').trim().isEmpty,
      ))
        'Every wrong option needs a misconception.',
    ],
  ];
}
