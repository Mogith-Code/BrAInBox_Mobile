import 'package:freezed_annotation/freezed_annotation.dart';

part 'mistake_models.freezed.dart';
part 'mistake_models.g.dart';

/// The misconception linked to a wrong option.
@freezed
abstract class MistakeMisconception with _$MistakeMisconception {
  const factory MistakeMisconception({
    required String id,
    required String title,
    String? description,
  }) = _MistakeMisconception;

  factory MistakeMisconception.fromJson(Map<String, dynamic> json) =>
      _$MistakeMisconceptionFromJson(json);
}

/// One wrong MCQ answer (`MistakeOut` from `GET /mistakes`). The question
/// can be deleted later; then its fields are null.
@freezed
abstract class MistakeEntry with _$MistakeEntry {
  const factory MistakeEntry({
    required String id,
    String? question,
    String? yourAnswer,
    String? correctAnswer,
    String? explanation,
    @Default('') String mistakeType,
    MistakeMisconception? misconception,
    String? correction, // how to fix the misconception
    String? topic,
    String? topicNumber,
    int? unitNumber,
    String? source, // diagnostic | quiz | exam | practice
    @Default(false) bool isResolved,
    DateTime? createdAt,
  }) = _MistakeEntry;

  factory MistakeEntry.fromJson(Map<String, dynamic> json) =>
      _$MistakeEntryFromJson(json);
}

/// The two tabs of the journal (`?status=open|resolved`).
enum MistakeTab {
  open('To fix', 'open'),
  resolved('Fixed', 'resolved');

  const MistakeTab(this.label, this.apiValue);

  final String label;
  final String apiValue;
}
