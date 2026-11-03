import 'package:freezed_annotation/freezed_annotation.dart';

import 'insights_models.dart';

part 'insights_summary.freezed.dart';
part 'insights_summary.g.dart';

/// Time window for `GET /insights/summary?period=`.
enum InsightsPeriod {
  week('week', 'This week'),
  month('month', 'This month'),
  all('all', 'All time');

  const InsightsPeriod(this.apiValue, this.label);

  /// Value sent in the `period` query.
  final String apiValue;

  /// "This week" (selector).
  final String label;

  /// "this week" (inside a sentence, e.g. "13.7h this week").
  String get inlineLabel => this == all ? 'in total' : label.toLowerCase();
}

/// Mastery group a topic falls in, as decided by the backend.
/// New values become [unknown] instead of crashing.
enum MasteryBandKey {
  @JsonValue('mastered')
  mastered,
  @JsonValue('strong')
  strong,
  @JsonValue('improving')
  improving,
  @JsonValue('weak')
  weak,
  @JsonValue('unknown')
  unknown,
}

/// Response of `GET /insights/summary`.
///
/// Every section is null when the backend has no data for it; the card then
/// shows its own empty state. Nothing here is computed in the app.
@freezed
abstract class InsightsSummary with _$InsightsSummary {
  const factory InsightsSummary({
    /// Echo of the requested period (`week`, `month`, `all`).
    @Default('week') String period,

    /// ISO dates (`2026-10-26`). Null for `all`.
    String? periodStart,
    String? periodEnd,
    MasterySummary? mastery,
    StudyTimeSummary? studyTime,
    AccuracyTrend? accuracyTrend,

    /// Syllabus units in syllabus order.
    @Default(<UnitMastery>[]) List<UnitMastery> units,
  }) = _InsightsSummary;

  factory InsightsSummary.fromJson(Map<String, dynamic> json) =>
      _$InsightsSummaryFromJson(json);
}

/// The mastery ring and its legend.
@freezed
abstract class MasterySummary with _$MasterySummary {
  const factory MasterySummary({
    /// Null when nothing was attempted. Show "—", never 0 %.
    double? percent,

    /// In display order (mastered first).
    @Default(<MasteryBand>[]) List<MasteryBand> bands,
  }) = _MasterySummary;

  factory MasterySummary.fromJson(Map<String, dynamic> json) =>
      _$MasterySummaryFromJson(json);
}

/// One legend row: "Mastered · 11 topics".
@freezed
abstract class MasteryBand with _$MasteryBand {
  const factory MasteryBand({
    @JsonKey(unknownEnumValue: MasteryBandKey.unknown)
    @Default(MasteryBandKey.unknown)
    MasteryBandKey key,
    required String label,
    @Default(0) int topicCount,
  }) = _MasteryBand;

  factory MasteryBand.fromJson(Map<String, dynamic> json) =>
      _$MasteryBandFromJson(json);
}

/// Time spent answering questions in the period.
@freezed
abstract class StudyTimeSummary with _$StudyTimeSummary {
  const factory StudyTimeSummary({
    @Default(0) int totalMinutes,

    /// One bar per day (week) or per week (month / all), oldest first.
    @Default(<StudyTimeBar>[]) List<StudyTimeBar> bars,
  }) = _StudyTimeSummary;

  factory StudyTimeSummary.fromJson(Map<String, dynamic> json) =>
      _$StudyTimeSummaryFromJson(json);
}

/// One bar of the study time chart.
@freezed
abstract class StudyTimeBar with _$StudyTimeBar {
  const factory StudyTimeBar({
    /// Axis label from the backend: "M", "T"... or "W1", "W2"...
    required String label,

    /// ISO date the bar starts on.
    String? date,
    @Default(0) int minutes,

    /// Drawn in the accent colour (today / the current week).
    @Default(false) bool highlight,
  }) = _StudyTimeBar;

  factory StudyTimeBar.fromJson(Map<String, dynamic> json) =>
      _$StudyTimeBarFromJson(json);
}

/// MCQ accuracy over recent weeks.
@freezed
abstract class AccuracyTrend with _$AccuracyTrend {
  const factory AccuracyTrend({
    /// Change from the first to the last point, in percentage points.
    /// Null when there are not enough points.
    double? changePoints,

    /// "8 wks": the window the change covers.
    @Default('') String windowLabel,

    /// Oldest first.
    @Default(<AccuracyPoint>[]) List<AccuracyPoint> points,
  }) = _AccuracyTrend;

  factory AccuracyTrend.fromJson(Map<String, dynamic> json) =>
      _$AccuracyTrendFromJson(json);
}

/// One point of the accuracy trend.
@freezed
abstract class AccuracyPoint with _$AccuracyPoint {
  const factory AccuracyPoint({
    required String label,
    String? periodStart,

    /// Null for a week with no answers (drawn as a gap).
    double? percent,
  }) = _AccuracyPoint;

  factory AccuracyPoint.fromJson(Map<String, dynamic> json) =>
      _$AccuracyPointFromJson(json);
}

/// Mastery of one syllabus unit.
@freezed
abstract class UnitMastery with _$UnitMastery {
  const factory UnitMastery({
    String? unitId,
    int? unitNumber,
    required String name,

    /// Null when nothing in the unit was attempted.
    double? percent,
    @JsonKey(unknownEnumValue: TopicStatus.unknown)
    @Default(TopicStatus.unknown)
    TopicStatus status,
  }) = _UnitMastery;

  factory UnitMastery.fromJson(Map<String, dynamic> json) =>
      _$UnitMasteryFromJson(json);
}
