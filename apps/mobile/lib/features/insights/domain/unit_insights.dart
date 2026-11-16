import 'package:freezed_annotation/freezed_annotation.dart';

import 'insights_models.dart';

part 'unit_insights.freezed.dart';
part 'unit_insights.g.dart';

/// Response of `GET /insights/units`: the student's mastery of every unit.
@freezed
abstract class UnitInsights with _$UnitInsights {
  const factory UnitInsights({
    /// Syllabus order (Unit 1 first). Keep this order.
    @Default(<UnitMastery>[]) List<UnitMastery> units,
    @Default(0) int assessedUnits,
    @Default(0) int totalUnits,
    @Default('') String note,
  }) = _UnitInsights;

  factory UnitInsights.fromJson(Map<String, dynamic> json) =>
      _$UnitInsightsFromJson(json);
}

/// One unit's current mastery, as measured by the backend.
@freezed
abstract class UnitMastery with _$UnitMastery {
  const factory UnitMastery({
    required String unitId,
    required int number,
    required String title,
    @Default(0) int topicCount,

    /// 0 - 100. Null when the unit was never measured: shown as "—",
    /// never 0 %.
    int? mastery,
    String? grade,
    String? gradeLabel,
    @JsonKey(unknownEnumValue: TopicStatus.unknown)
    @Default(TopicStatus.unknown)
    TopicStatus status,
    @Default('') String understanding,

    /// Change since 7 days ago, in points. Null when there is nothing older
    /// to compare with.
    int? changeWeek,
  }) = _UnitMastery;

  factory UnitMastery.fromJson(Map<String, dynamic> json) =>
      _$UnitMasteryFromJson(json);
}
