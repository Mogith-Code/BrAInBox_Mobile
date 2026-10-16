import 'package:freezed_annotation/freezed_annotation.dart';

import 'mcq_option.dart';

part 'question.freezed.dart';
part 'question.g.dart';

enum QuestionType { mcq, structured, essay }

/// A practice / exam question.
///
// TODO(udith): check these fields against the backend OpenAPI /docs.
@freezed
abstract class Question with _$Question {
  const factory Question({
    required String id,
    required String topicId,
    required String stem, // the question text
    @Default(QuestionType.mcq) QuestionType type,
    @Default(<McqOption>[])
    List<McqOption> options, // empty for structured/essay
    String? explanation,
    @Default(false) bool isAiGenerated, // show AiBadge when true
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}
