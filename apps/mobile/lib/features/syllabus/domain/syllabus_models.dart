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
