import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Question, AiJob;

part 'exams_models.freezed.dart';
part 'exams_models.g.dart';

/// The 10 Sri Lankan G.C.E. A/L Biology curriculum units.
const Map<int, String> kBiologyUnits = {
  1: 'Introduction to Biology',
  2: 'Chemical and Cellular Basis of Life',
  3: 'Evolution and Diversity of Organisms',
  4: 'Plant Form and Function',
  5: 'Animal Form and Function',
  6: 'Genetics',
  7: 'Molecular Biology and Recombinant DNA Technology',
  8: 'Environmental Biology',
  9: 'Microbiology',
  10: 'Applied Biology',
};

/// A single multiple-choice question in an exam paper.
@freezed
abstract class ExamQuestion with _$ExamQuestion {
  const factory ExamQuestion({
    required String id,
    String? topicId,
    @Default('') String topic,
    required String question,
    @Default([]) List<String> options,
    @Default(1) int marks,
    String? correctAnswer,
  }) = _ExamQuestion;

  factory ExamQuestion.fromJson(Map<String, dynamic> json) =>
      _$ExamQuestionFromJson(json);
}

/// An exam paper generated for the student.
@freezed
abstract class ExamPaper with _$ExamPaper {
  const factory ExamPaper({
    required String paperId,
    @Default('') String title,
    @Default(0) int totalQuestions,
    @Default([]) List<ExamQuestion> questions,
    @Default([]) List<String> warnings,
  }) = _ExamPaper;

  factory ExamPaper.fromJson(Map<String, dynamic> json) =>
      _$ExamPaperFromJson(json);
}

/// One student answer for an exam question ("A".."E" or null if skipped).
@freezed
abstract class AnswerItem with _$AnswerItem {
  const factory AnswerItem({
    required String questionId,
    String? selected,
    String? answerText,
  }) = _AnswerItem;

  factory AnswerItem.fromJson(Map<String, dynamic> json) =>
      _$AnswerItemFromJson(json);
}

/// The evaluation result of one individual question.
@freezed
abstract class QuestionResult with _$QuestionResult {
  const factory QuestionResult({
    required String questionId,
    @Default('') String topic,
    required String question,
    String? selectedOption,
    @Default('') String correctAnswer,
    @Default(false) bool isCorrect,
    @Default(0) int marksAwarded,
    String? explanation,
  }) = _QuestionResult;

  factory QuestionResult.fromJson(Map<String, dynamic> json) =>
      _$QuestionResultFromJson(json);
}

/// Breakdown of score for one topic.
@freezed
abstract class TopicScore with _$TopicScore {
  const factory TopicScore({
    required String topic,
    @Default(0) int correct,
    @Default(0) int total,
    @Default(0.0) double percent,
  }) = _TopicScore;

  factory TopicScore.fromJson(Map<String, dynamic> json) =>
      _$TopicScoreFromJson(json);
}

/// The overall evaluation response for a submitted paper.
@freezed
abstract class EvalResult with _$EvalResult {
  const factory EvalResult({
    required String paperId,
    String? attemptId,
    @Default(0) int totalQuestions,
    @Default(0) int answered,
    @Default(0) int correct,
    @Default(0) int marksObtained,
    @Default(0) int marksTotal,
    @Default(0.0) double percent,
    @Default([]) List<TopicScore> byTopic,
    @Default([]) List<String> weakTopics,
    @Default([]) List<QuestionResult> results,
    // "marking" while structured / essay answers are marked in the background.
    @Default('graded') String status,
    @Default(0) int pendingWritten,
    @Default(0) int writtenMarksTotal,
  }) = _EvalResult;

  factory EvalResult.fromJson(Map<String, dynamic> json) =>
      _$EvalResultFromJson(json);
}

/// Summary / status for past papers.
@freezed
abstract class ExamsSummary with _$ExamsSummary {
  const factory ExamsSummary({
    required String title,
    @Default('') String message,
  }) = _ExamsSummary;

  factory ExamsSummary.fromJson(Map<String, dynamic> json) =>
      _$ExamsSummaryFromJson(json);
}
