import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'learn_models.freezed.dart';
part 'learn_models.g.dart';

// Notes, AI jobs, media, bookmarks and uploads for the Learn tab.
// JSON follows the Learn API (`/api/v1/learn/...`, snake_case).

// ---------------------------------------------------------------------------
// Notes
// ---------------------------------------------------------------------------

/// Full notes or short (revision) notes.
enum NoteType {
  @JsonValue('full')
  full,
  @JsonValue('short')
  short,
}

/// How long the generated notes should be.
enum NoteDepth {
  @JsonValue('detailed')
  detailed('Detailed', '~12 min read'),
  @JsonValue('standard')
  standard('Standard', '~6 min read'),
  @JsonValue('quick')
  quick('Quick', '~2 min read');

  const NoteDepth(this.label, this.readTime);

  final String label;
  final String readTime;
}

/// One piece of a note. The backend sends notes as a list of typed blocks:
/// `{"type": "paragraph", "text": "...", "highlights": ["allele"]}`.
/// Unknown block types are kept as [UnknownBlock] and not shown.
@Freezed(
  unionKey: 'type',
  unionValueCase: FreezedUnionCase.snake,
  fallbackUnion: 'unknown',
)
sealed class NoteBlock with _$NoteBlock {
  const factory NoteBlock.heading({
    required String text,

    /// 1 = biggest. Notes usually use 2 and 3.
    @Default(2) int level,
  }) = HeadingBlock;

  /// Plain text; every term in [highlights] gets an amber highlight.
  const factory NoteBlock.paragraph({
    required String text,
    @Default(<String>[]) List<String> highlights,
  }) = ParagraphBlock;

  /// Teal "Definition" callout.
  const factory NoteBlock.definition({
    @Default('') String term,
    required String text,
  }) = DefinitionBlock;

  /// Indigo "Past-paper tip" callout with a lightbulb.
  const factory NoteBlock.tip({
    @Default('Past-paper tip') String title,
    required String text,
  }) = TipBlock;

  const factory NoteBlock.bulletList({
    @Default(<String>[]) List<String> items,
  }) = BulletListBlock;

  const factory NoteBlock.table({
    @Default(<String>[]) List<String> headers,
    @Default(<List<String>>[]) List<List<String>> rows,
    String? caption,
  }) = TableBlock;

  /// A figure. `url` may be `image_url` in the JSON.
  const factory NoteBlock.image({
    @JsonKey(readValue: _readImageUrl) required String url,
    String? caption,
  }) = ImageBlock;

  const factory NoteBlock.unknown() = UnknownBlock;

  factory NoteBlock.fromJson(Map<String, dynamic> json) =>
      _$NoteBlockFromJson(json);
}

/// Notes for a topic. `GET /learn/topics/{topicId}/notes?type=full|short`.
@freezed
abstract class TopicNote with _$TopicNote {
  const factory TopicNote({
    required String id,
    @Default(NoteType.full) NoteType type,
    @Default(<NoteBlock>[]) List<NoteBlock> blocks,
    @Default(0) int readMinutes,
    @Default(false) bool aiGenerated,
    DateTime? createdAt,
  }) = _TopicNote;

  factory TopicNote.fromJson(Map<String, dynamic> json) => _$TopicNoteFromJson(json);
}

/// Body of `POST /learn/topics/{topicId}/notes/generate`.
@freezed
abstract class NoteGenerationRequest with _$NoteGenerationRequest {
  const factory NoteGenerationRequest({
    @Default(NoteType.full) NoteType type,
    @Default(NoteDepth.standard) NoteDepth depth,
    @Default(true) bool includeExamples,
    @Default(true) bool includePastPaperTips,
  }) = _NoteGenerationRequest;

  factory NoteGenerationRequest.fromJson(Map<String, dynamic> json) =>
      _$NoteGenerationRequestFromJson(json);
}

enum JobStatus {
  @JsonValue('queued')
  queued,
  @JsonValue('running')
  running,
  @JsonValue('done')
  done,
  @JsonValue('failed')
  failed;

  bool get isFinished => this == done || this == failed;
}

/// `GET /learn/jobs/{jobId}` → `{status, result_id, error}`.
@freezed
abstract class GenerationJob with _$GenerationJob {
  const factory GenerationJob({
    @JsonKey(unknownEnumValue: JobStatus.running)
    @Default(JobStatus.queued)
    JobStatus status,
    String? resultId,
    String? error,
  }) = _GenerationJob;

  factory GenerationJob.fromJson(Map<String, dynamic> json) =>
      _$GenerationJobFromJson(json);
}

// ---------------------------------------------------------------------------
// Topic media and practice
// ---------------------------------------------------------------------------

/// A stored diagram. Item of `GET /learn/topics/{topicId}/diagrams`.
@freezed
abstract class Diagram with _$Diagram {
  const factory Diagram({
    required String id,
    required String imageUrl,
    @Default('') String caption,
    @Default(false) bool aiGenerated,
  }) = _Diagram;

  factory Diagram.fromJson(Map<String, dynamic> json) =>
      _$DiagramFromJson(json);
}

/// Item of `GET /learn/topics/{topicId}/videos`.
@freezed
abstract class Video with _$Video {
  const Video._();

  const factory Video({
    required String id,
    required String title,
    required String url,
    String? thumbnailUrl,
    @Default(0) int durationSeconds,
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);

  /// "12:05" or "1:02:05".
  String get durationLabel {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }
}

/// `GET /learn/topics/{topicId}/practice-summary`.
@freezed
abstract class PracticeSummary with _$PracticeSummary {
  const factory PracticeSummary({
    @Default(0) int questionCount,

    /// 0-100. Null until the student has answered something.
    double? accuracyPercent,
    DateTime? lastAttemptAt,
  }) = _PracticeSummary;

  factory PracticeSummary.fromJson(Map<String, dynamic> json) =>
      _$PracticeSummaryFromJson(json);
}

/// `POST /learn/topics/{topicId}/progress` → `event`.
enum ProgressEvent { opened, read }

// ---------------------------------------------------------------------------
// Library
// ---------------------------------------------------------------------------

enum BookmarkKind {
  @JsonValue('topic')
  topic,
  @JsonValue('short_note')
  shortNote,
}

/// Item of `GET /learn/bookmarks`: a bookmarked topic, or a short note the
/// student saved from an upload.
@freezed
abstract class Bookmark with _$Bookmark {
  const factory Bookmark({
    @JsonKey(unknownEnumValue: BookmarkKind.topic)
    @Default(BookmarkKind.topic)
    BookmarkKind kind,
    @Default('') String topicId,
    @Default('') String topicTitle,
    @Default('') String unitTitle,
    @Default(0) int unitOrder,

    /// Short notes only.
    String? noteId,
    String? uploadId,
    String? title,
    String? preview,
    DateTime? createdAt,
  }) = _Bookmark;

  factory Bookmark.fromJson(Map<String, dynamic> json) =>
      _$BookmarkFromJson(json);
}

// ---------------------------------------------------------------------------
// Uploads
// ---------------------------------------------------------------------------

enum UploadStatus {
  /// Client only: the file is still being sent.
  @JsonValue('uploading')
  uploading,
  @JsonValue('queued')
  queued,
  @JsonValue('processing')
  processing,
  @JsonValue('done')
  done,
  @JsonValue('failed')
  failed;

  bool get isBusy => this == uploading || this == queued || this == processing;
}

enum SummaryLength {
  @JsonValue('short')
  short('Short'),
  @JsonValue('medium')
  medium('Medium'),
  @JsonValue('detailed')
  detailed('Detailed');

  const SummaryLength(this.label);

  final String label;
}

/// The topic an upload is linked to.
@freezed
abstract class UploadTopic with _$UploadTopic {
  const factory UploadTopic({required String id, @Default('') String title}) =
      _UploadTopic;

  factory UploadTopic.fromJson(Map<String, dynamic> json) =>
      _$UploadTopicFromJson(json);
}

/// One uploaded file. `GET /learn/uploads` (list) and `/uploads/{id}`
/// (detail: summary, key points, extracted text).
@freezed
abstract class Upload with _$Upload {
  const factory Upload({
    /// `id` or `upload_id`.
    @JsonKey(readValue: _readUploadId) required String id,
    @JsonKey(readValue: _readFileName) @Default('') String fileName,
    @JsonKey(unknownEnumValue: UploadStatus.processing)
    @Default(UploadStatus.processing)
    UploadStatus status,
    DateTime? createdAt,
    UploadTopic? topic,
    String? summary,
    @Default(<String>[]) List<String> keyPoints,
    String? extractedText,
    String? error,

    /// Client only: 0-1 while [UploadStatus.uploading].
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(0)
    double sendProgress,
  }) = _Upload;

  factory Upload.fromJson(Map<String, dynamic> json) => _$UploadFromJson(json);
}

/// A file the student picked, before it is uploaded. Not JSON.
class PickedUploadFile {
  const PickedUploadFile({
    required this.name,
    this.path,
    this.bytes,
    this.size = 0,
  }) : assert(path != null || bytes != null, 'Need a path or bytes');

  final String name;

  /// Phone storage path (Android / iOS).
  final String? path;

  /// File contents (web, or when picked into memory).
  final Uint8List? bytes;
  final int size;

  static const allowedExtensions = ['pdf', 'docx', 'txt', 'jpg', 'jpeg', 'png'];

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

Object? _readImageUrl(Map<dynamic, dynamic> json, String key) =>
    json['url'] ?? json['image_url'];

Object? _readUploadId(Map<dynamic, dynamic> json, String key) =>
    json['id'] ?? json['upload_id'];

Object? _readFileName(Map<dynamic, dynamic> json, String key) =>
    json['file_name'] ?? json['filename'] ?? json['name'];
