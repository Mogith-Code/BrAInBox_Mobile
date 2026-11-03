import 'package:freezed_annotation/freezed_annotation.dart';

// Shared models this feature uses live in brainbox_core.
// Re-exported so feature code can import just this file.
export 'package:brainbox_core/brainbox_core.dart' show Unit, Topic, Concept;

part 'syllabus_models.freezed.dart';
part 'syllabus_models.g.dart';

/// How the student is doing in a unit (the pill on each Learn card).
enum UnitStatus {
  @JsonValue('mastered')
  mastered,
  @JsonValue('strong')
  strong,
  @JsonValue('improving')
  improving,
  @JsonValue('weak')
  weak,
}

/// How the student is doing in a topic (the pill on each topic row, B3).
enum TopicStatus {
  @JsonValue('mastered')
  mastered,
  @JsonValue('strong')
  strong,
  @JsonValue('improving')
  improving,
  @JsonValue('weak')
  weak,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('not_started')
  notStarted,
}

/// One card on the Learn screen (Figma B2): a unit with the student's mastery.
///
/// One item of `GET /units`.
@freezed
abstract class UnitProgress with _$UnitProgress {
  const factory UnitProgress({
    required String id,
    required String title,
    @Default(0) int order, // 1-based position in the syllabus
    @Default(0) int topicCount,
    @Default(0) double mastery, // 0-1 or 0-100
    @Default(UnitStatus.improving) UnitStatus status,

    /// Topic titles, so the search box can match topics too.
    @Default(<String>[]) List<String> topicTitles,
  }) = _UnitProgress;

  factory UnitProgress.fromJson(Map<String, dynamic> json) =>
      _$UnitProgressFromJson(json);
}

/// One topic row on the Unit detail screen (Figma B3).
@freezed
abstract class TopicProgress with _$TopicProgress {
  const factory TopicProgress({
    required String id,
    required String unitId,
    required String title,
    @Default(0) int order, // 1-based position in the unit
    @JsonKey(unknownEnumValue: TopicStatus.notStarted)
    @Default(TopicStatus.notStarted)
    TopicStatus status,
    @Default(0) double progress, // 0-1, shown as a bar while in progress
  }) = _TopicProgress;

  factory TopicProgress.fromJson(Map<String, dynamic> json) =>
      _$TopicProgressFromJson(json);
}

/// A unit with its topics (Figma B3). `GET /units/{unit_id}`.
@freezed
abstract class UnitDetail with _$UnitDetail {
  const UnitDetail._();

  const factory UnitDetail({
    required UnitProgress unit,
    @Default(<TopicProgress>[]) List<TopicProgress> topics,
  }) = _UnitDetail;

  factory UnitDetail.fromJson(Map<String, dynamic> json) =>
      _$UnitDetailFromJson(json);

  int get masteredCount =>
      topics.where((t) => t.status == TopicStatus.mastered).length;

  int get weakCount => topics.where((t) => t.status == TopicStatus.weak).length;
}

/// One topic with the unit it belongs to (Figma B4). `GET /topics/{topic_id}`.
@freezed
abstract class TopicDetail with _$TopicDetail {
  const factory TopicDetail({
    required TopicProgress topic,
    required UnitProgress unit,

    /// Bookmarked into "My library".
    @Default(false) bool saved,
  }) = _TopicDetail;

  factory TopicDetail.fromJson(Map<String, dynamic> json) =>
      _$TopicDetailFromJson(json);
}

/// 88 or 0.88 -> 0.88
double masteryFraction(double value) => value > 1 ? value / 100 : value;

/// Units whose title or one of whose topics contains [query] (any case).
List<UnitProgress> filterUnits(List<UnitProgress> units, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return units;
  return [
    for (final unit in units)
      if (unit.title.toLowerCase().contains(q) ||
          unit.topicTitles.any((t) => t.toLowerCase().contains(q)))
        unit,
  ];
}
