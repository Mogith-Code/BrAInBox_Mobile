import 'package:freezed_annotation/freezed_annotation.dart';

part 'mcq_option.freezed.dart';
part 'mcq_option.g.dart';

/// One answer option of an MCQ [Question].
///
// TODO(udith): check these fields against the backend OpenAPI /docs.
@freezed
abstract class McqOption with _$McqOption {
  const factory McqOption({
    required String id,
    required String text,
    @Default(false) bool isCorrect, // only sent after the student answers
    String? misconceptionTag, // why a student might pick this wrong option
  }) = _McqOption;

  factory McqOption.fromJson(Map<String, dynamic> json) =>
      _$McqOptionFromJson(json);
}
