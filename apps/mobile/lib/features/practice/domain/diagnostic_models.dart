import 'package:freezed_annotation/freezed_annotation.dart';

part 'diagnostic_models.freezed.dart';
part 'diagnostic_models.g.dart';

/// One answer option ("A" + text).
@freezed
abstract class DiagnosticOption with _$DiagnosticOption {
  const factory DiagnosticOption({
    required String id,
    required String label, // "A" ... "E"
    required String text,
  }) = _DiagnosticOption;

  factory DiagnosticOption.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticOptionFromJson(json);
}

/// One diagnostic MCQ.
@freezed
abstract class DiagnosticQuestion with _$DiagnosticQuestion {
  const factory DiagnosticQuestion({
    required String id,
    required String unitCode,
    required String unitTitle,
    required String stem,
    @Default(<DiagnosticOption>[]) List<DiagnosticOption> options,

    /// Set when the question was already answered (resuming an attempt).
    /// TODO(udith): ask the backend to return this from /diagnostic/start.
    String? selectedOptionId,
  }) = _DiagnosticQuestion;

  factory DiagnosticQuestion.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticQuestionFromJson(json);
}

/// `POST /diagnostic/start` (the same attempt comes back after a restart).
@freezed
abstract class DiagnosticAttempt with _$DiagnosticAttempt {
  const factory DiagnosticAttempt({
    required String attemptId,
    required int total,
    @Default(10) int minutes,
    @Default(<DiagnosticQuestion>[]) List<DiagnosticQuestion> questions,
  }) = _DiagnosticAttempt;

  factory DiagnosticAttempt.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticAttemptFromJson(json);
}

/// `POST /diagnostic/{id}/answer`
@freezed
abstract class AnswerSaved with _$AnswerSaved {
  const factory AnswerSaved({
    @Default(true) bool saved,
    @Default(0) int answered,
    @Default(0) int total,
  }) = _AnswerSaved;

  factory AnswerSaved.fromJson(Map<String, dynamic> json) =>
      _$AnswerSavedFromJson(json);
}

enum UnitStatus {
  strong,
  ok,
  @JsonValue('needs_work')
  needsWork,
}

/// A unit mentioned by the result ("Unit 4 · Plant Form & Function").
@freezed
abstract class UnitRef with _$UnitRef {
  const UnitRef._();

  const factory UnitRef({required String unitCode, required String unitTitle}) =
      _UnitRef;

  factory UnitRef.fromJson(Map<String, dynamic> json) =>
      _$UnitRefFromJson(json);

  /// "U4" / "unit_4" / "4" -> "Unit 4".
  String get unitLabel => unitLabelFor(unitCode);
}

/// One row of "Mastery by unit".
@freezed
abstract class UnitResult with _$UnitResult {
  const UnitResult._();

  const factory UnitResult({
    required String unitCode,
    required String unitTitle,
    required double mastery, // 0-1 or 0-100, see [fraction]
    @JsonKey(unknownEnumValue: UnitStatus.ok)
    @Default(UnitStatus.ok)
    UnitStatus status,
  }) = _UnitResult;

  factory UnitResult.fromJson(Map<String, dynamic> json) =>
      _$UnitResultFromJson(json);

  /// Mastery as 0.0 - 1.0, whichever scale the backend used.
  double get fraction => mastery > 1 ? mastery / 100 : mastery;
}

/// `POST /diagnostic/{id}/submit` and `GET /diagnostic/result`.
@freezed
abstract class DiagnosticResult with _$DiagnosticResult {
  const factory DiagnosticResult({
    required String attemptId,
    DateTime? completedAt,
    @Default(0) int score,
    @Default(0) int total,
    UnitRef? strongest,
    UnitRef? needsWork,
    @Default(<UnitResult>[]) List<UnitResult> units,
    @Default('') String summary,
    @Default(true) bool summaryAiGenerated,
    @Default('Formative feedback — not an official exam mark.')
    String disclaimer,
  }) = _DiagnosticResult;

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) =>
      _$DiagnosticResultFromJson(json);
}

/// "U4" / "unit_4" / "4" -> "Unit 4" (or the code itself if it has no
/// number).
String unitLabelFor(String unitCode) {
  final number = RegExp(r'\d+').firstMatch(unitCode)?.group(0);
  return number == null ? unitCode : 'Unit $number';
}
