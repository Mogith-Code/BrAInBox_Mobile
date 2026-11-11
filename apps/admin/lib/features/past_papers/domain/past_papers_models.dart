import 'package:freezed_annotation/freezed_annotation.dart';

part 'past_papers_models.freezed.dart';
part 'past_papers_models.g.dart';

enum PaperType {
  @JsonValue('paper_1_mcq')
  paper1Mcq('Paper I · MCQ'),
  @JsonValue('paper_2_structured')
  paper2Structured('Paper II · Structured & Essay');

  const PaperType(this.label);

  final String label;

  String get apiValue => switch (this) {
    paper1Mcq => 'paper_1_mcq',
    paper2Structured => 'paper_2_structured',
  };
}

/// Backend values: done | running | low_confidence | failed.
enum ExtractionStatus {
  done,
  running,
  @JsonValue('low_confidence')
  lowConfidence,
  failed,
}

/// One uploaded past paper (`GET /admin/questions/past-papers`).
@freezed
abstract class PastPaper with _$PastPaper {
  const factory PastPaper({
    required String id,
    required int year,
    @JsonKey(unknownEnumValue: PaperType.paper1Mcq)
    @Default(PaperType.paper1Mcq)
    PaperType paperType,
    @Default(false) bool schemeLinked,
    @JsonKey(unknownEnumValue: ExtractionStatus.running)
    @Default(ExtractionStatus.running)
    ExtractionStatus extraction,
    @Default(0) int questionsExtracted,
    @Default(0) double progress, // 0.0 - 1.0 while running
    @Default(0) int lowConfidence, // questions the OCR is unsure about
    @Default(false) bool outdatedSyllabus,
  }) = _PastPaper;

  factory PastPaper.fromJson(Map<String, dynamic> json) =>
      _$PastPaperFromJson(json);
}

/// One extracted question with its model answer and marking keywords.
@freezed
abstract class PaperQuestion with _$PaperQuestion {
  const factory PaperQuestion({
    required String id,
    required String label, // "Q3 (b)"
    @Default(0) int marks,
    @Default('') String text,
    double? ocrConfidence, // 0.0 - 1.0
    @Default('') String modelAnswer,
    @Default([]) List<String> keywords,
    @Default([]) List<String> suggestedKeywords, // AI, from the marking scheme
  }) = _PaperQuestion;

  factory PaperQuestion.fromJson(Map<String, dynamic> json) =>
      _$PaperQuestionFromJson(json);
}
