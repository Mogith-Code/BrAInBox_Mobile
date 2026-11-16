import 'package:freezed_annotation/freezed_annotation.dart';

part 'syllabus_models.freezed.dart';
part 'syllabus_models.g.dart';

// Models for the Learn tab's syllabus screens. JSON follows the Learn API
// (`/api/v1/learn/...`, snake_case). Notes, media, jobs and uploads are in
// `learn_models.dart`.

/// How well the student knows a unit or topic (the mastery chip).
enum MasteryLevel {
  @JsonValue('weak')
  weak,
  @JsonValue('improving')
  improving,
  @JsonValue('strong')
  strong,
  @JsonValue('mastered')
  mastered,
}

/// Where the student is with a topic (the pill on each topic row).
enum TopicStatus {
  @JsonValue('not_started')
  notStarted,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('mastered')
  mastered,
}

/// A subject (Biology, Chemistry, Physics). `GET /learn/subjects`.
@freezed
abstract class Subject with _$Subject {
  const factory Subject({
    required String id,
    required String name,

    /// False = "coming soon" (only Biology has content for now).
    @Default(false) bool available,
  }) = _Subject;

  factory Subject.fromJson(Map<String, dynamic> json) =>
      _$SubjectFromJson(json);
}

/// One unit card on the Learn screen. Item of
/// `GET /learn/subjects/{subjectId}/units`.
@freezed
abstract class UnitProgress with _$UnitProgress {
  const UnitProgress._();

  const factory UnitProgress({
    required String id,
    required String title,

    /// 1-based position in the syllabus ("UNIT 6"). Read from `order` or
    /// `number`.
    @JsonKey(readValue: _readOrder) @Default(0) int order,
    @Default(0) int topicCount,

    /// 0-100.
    @Default(0) double masteryPercent,
    @JsonKey(unknownEnumValue: MasteryLevel.improving)
    @Default(MasteryLevel.improving)
    MasteryLevel masteryLevel,
  }) = _UnitProgress;

  factory UnitProgress.fromJson(Map<String, dynamic> json) =>
      _$UnitProgressFromJson(json);

  /// 0-1, for rings.
  double get mastery => percentToFraction(masteryPercent);
}

/// One topic row on the Unit detail screen.
@freezed
abstract class TopicProgress with _$TopicProgress {
  const TopicProgress._();

  const factory TopicProgress({
    required String id,
    @Default('') String unitId,
    required String title,
    @JsonKey(readValue: _readOrder) @Default(0) int order,
    @JsonKey(unknownEnumValue: TopicStatus.notStarted)
    @Default(TopicStatus.notStarted)
    TopicStatus status,

    /// 0-100, shown as a mini bar while in progress.
    @Default(0) double progressPercent,

    /// Flagged weak from the student's answers (orange dot).
    @Default(false) bool isWeak,
  }) = _TopicProgress;

  factory TopicProgress.fromJson(Map<String, dynamic> json) =>
      _$TopicProgressFromJson(json);

  /// 0-1.
  double get progress => percentToFraction(progressPercent);
}

/// A unit with its topics. `GET /learn/units/{unitId}`.
@freezed
abstract class UnitDetail with _$UnitDetail {
  const UnitDetail._();

  const factory UnitDetail({
    required UnitProgress unit,
    @Default(<TopicProgress>[]) List<TopicProgress> topics,

    /// Counts from the server; worked out from [topics] when missing.
    int? masteredTopics,
    int? weakTopics,
  }) = _UnitDetail;

  factory UnitDetail.fromJson(Map<String, dynamic> json) =>
      _$UnitDetailFromJson(json);

  /// Reads the API body. Accepts the unit's fields at the top level
  /// (`{id, title, ..., topics: [], counts: {mastered, weak}}`) or nested
  /// under `unit`.
  factory UnitDetail.fromApi(Map<String, dynamic> json) {
    final unitJson = json['unit'] is Map
        ? Map<String, dynamic>.from(json['unit'] as Map)
        : json;
    final unit = UnitProgress.fromJson(unitJson);
    final topics = [
      for (final t in (json['topics'] ?? unitJson['topics'] ?? []) as List)
        TopicProgress.fromJson({
          'unit_id': unit.id,
          ...Map<String, dynamic>.from(t as Map),
        }),
    ];
    final counts = json['counts'] is Map ? json['counts'] as Map : json;
    return UnitDetail(
      unit: unit.topicCount == 0
          ? unit.copyWith(topicCount: topics.length)
          : unit,
      topics: topics,
      masteredTopics: _asInt(counts['mastered'] ?? counts['mastered_count']),
      weakTopics: _asInt(counts['weak'] ?? counts['weak_count']),
    );
  }

  int get masteredCount =>
      masteredTopics ??
      topics.where((t) => t.status == TopicStatus.mastered).length;

  int get weakCount => weakTopics ?? topics.where((t) => t.isWeak).length;
}

/// One topic page. `GET /learn/topics/{topicId}`.
@freezed
abstract class TopicDetail with _$TopicDetail {
  const TopicDetail._();

  const factory TopicDetail({
    required TopicProgress topic,
    required UnitProgress unit,

    /// e.g. `['Biology', 'Unit 6', 'Mendelian inheritance']`.
    @Default(<String>[]) List<String> breadcrumb,
    @JsonKey(unknownEnumValue: MasteryLevel.improving)
    @Default(MasteryLevel.improving)
    MasteryLevel masteryLevel,
    @Default(0) double masteryPercent,

    /// Bookmarked into the Library.
    @Default(false) bool saved,

    /// Syllabus section, e.g. `6.1`.
    String? syllabusCode,

    /// e.g. `2017`. With [isOutdated] the topic gets an "older syllabus" tag.
    String? syllabusVersion,
    @Default(false) bool isOutdated,
  }) = _TopicDetail;

  factory TopicDetail.fromJson(Map<String, dynamic> json) =>
      _$TopicDetailFromJson(json);

  /// Reads the flat API body:
  /// `{id, title, unit_id, unit_title, unit_order, status, ...,
  ///   breadcrumb, mastery_level, is_bookmarked, syllabus_version,
  ///   is_outdated}`. A nested `unit` object works too.
  factory TopicDetail.fromApi(Map<String, dynamic> json) {
    final topicJson = json['topic'] is Map
        ? Map<String, dynamic>.from(json['topic'] as Map)
        : json;
    final unit = json['unit'] is Map
        ? UnitProgress.fromJson(Map<String, dynamic>.from(json['unit'] as Map))
        : UnitProgress(
            id: '${json['unit_id'] ?? ''}',
            title: '${json['unit_title'] ?? ''}',
            order: _asInt(json['unit_order'] ?? json['unit_number']) ?? 0,
          );
    final crumbs = (json['breadcrumb'] as List?) ?? const [];
    return TopicDetail(
      topic: TopicProgress.fromJson({'unit_id': unit.id, ...topicJson}),
      unit: unit,
      breadcrumb: [
        for (final c in crumbs)
          c is Map ? '${c['title'] ?? c['name'] ?? ''}' : '$c',
      ],
      masteryLevel: MasteryLevel.values.firstWhere(
        (m) => m.name == json['mastery_level'],
        orElse: () => MasteryLevel.improving,
      ),
      masteryPercent: (json['mastery_percent'] as num?)?.toDouble() ?? 0,
      saved: json['is_bookmarked'] == true,
      syllabusCode: json['syllabus_code'] as String?,
      syllabusVersion: json['syllabus_version']?.toString(),
      isOutdated: json['is_outdated'] == true,
    );
  }

  /// "Biology › Unit 6 › Mendelian inheritance".
  String get breadcrumbText => breadcrumb.isNotEmpty
      ? breadcrumb.join(' › ')
      : 'Biology › Unit ${unit.order} › ${topic.title}';

  /// "Unit 6 · 6.1 Mendelian inheritance".
  String get syllabusTagText => [
    'Unit ${unit.order}',
    [?syllabusCode, topic.title].join(' '),
  ].join(' · ');
}

/// A topic that matched a search. Item of `GET /learn/search` → `topics`.
@freezed
abstract class TopicSearchHit with _$TopicSearchHit {
  const factory TopicSearchHit({
    required String id,
    required String title,
    @Default('') String unitId,
    @Default('') String unitTitle,
    @Default(0) int unitOrder,
  }) = _TopicSearchHit;

  factory TopicSearchHit.fromJson(Map<String, dynamic> json) =>
      _$TopicSearchHitFromJson(json);
}

/// `GET /learn/search?q=` → `{units: [], topics: []}`.
@freezed
abstract class SearchResult with _$SearchResult {
  const SearchResult._();

  const factory SearchResult({
    @Default(<UnitProgress>[]) List<UnitProgress> units,
    @Default(<TopicSearchHit>[]) List<TopicSearchHit> topics,
  }) = _SearchResult;

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);

  static const empty = SearchResult();

  bool get isEmpty => units.isEmpty && topics.isEmpty;
}

/// 88 or 0.88 -> 0.88. Values above 1 are read as percentages.
double percentToFraction(double value) =>
    (value > 1 ? value / 100 : value).clamp(0.0, 1.0);

/// Units whose title contains [query] (any case).
List<UnitProgress> filterUnits(List<UnitProgress> units, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return units;
  return [
    for (final unit in units)
      if (unit.title.toLowerCase().contains(q)) unit,
  ];
}

Object? _readOrder(Map<dynamic, dynamic> json, String key) =>
    json['order'] ?? json['number'];

int? _asInt(Object? value) => switch (value) {
  final int v => v,
  final num v => v.toInt(),
  final String v => int.tryParse(v),
  _ => null,
};
