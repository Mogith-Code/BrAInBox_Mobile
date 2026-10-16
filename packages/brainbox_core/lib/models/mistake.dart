import 'package:freezed_annotation/freezed_annotation.dart';

part 'mistake.freezed.dart';
part 'mistake.g.dart';

/// A wrong answer saved to the student's mistake journal.
///
// TODO(keshomigha): check these fields against the backend OpenAPI /docs.
@freezed
abstract class Mistake with _$Mistake {
  const factory Mistake({
    required String id,
    required String questionId,
    required String topicId,
    String? selectedOptionId,
    String? misconceptionTag,
    DateTime? createdAt,
  }) = _Mistake;

  factory Mistake.fromJson(Map<String, dynamic> json) =>
      _$MistakeFromJson(json);
}
