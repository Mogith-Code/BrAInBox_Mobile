import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';
part 'note.g.dart';

enum NoteKind { ai, short, uploaded }

/// Study notes for a topic (AI notes, short notes or uploaded notes).
///
// TODO(samni): check these fields against the backend OpenAPI /docs.
@freezed
abstract class Note with _$Note {
  const factory Note({
    required String id,
    required String topicId,
    required String title,
    @Default('') String markdown, // rendered with flutter_markdown_plus
    @Default(NoteKind.ai) NoteKind kind,
    @Default(false) bool isAiGenerated, // show AiBadge when true
    DateTime? updatedAt,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
}
