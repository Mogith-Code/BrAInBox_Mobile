import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_models.freezed.dart';
part 'home_models.g.dart';

/// Where a Next best action leads.
@freezed
abstract class ActionTarget with _$ActionTarget {
  const factory ActionTarget({String? unitCode, String? topicId}) =
      _ActionTarget;

  factory ActionTarget.fromJson(Map<String, dynamic> json) =>
      _$ActionTargetFromJson(json);
}

/// The gradient "NEXT BEST ACTION" card.
@freezed
abstract class NextBestAction with _$NextBestAction {
  const factory NextBestAction({
    required String type, // "diagnostic", "revision", "practice", ...
    required String title,
    @Default('') String reason,
    @Default('Start') String buttonLabel,
    int? minutes,
    ActionTarget? target,
    @Default(false) bool aiGenerated,
  }) = _NextBestAction;

  factory NextBestAction.fromJson(Map<String, dynamic> json) =>
      _$NextBestActionFromJson(json);
}

/// One row of "Today's plan".
@freezed
abstract class PlanItem with _$PlanItem {
  const factory PlanItem({
    required String id,
    required String title,
    @Default(0) int minutes,
    @Default('') String unitLabel, // "Unit 6"
    @Default(false) bool done,
  }) = _PlanItem;

  factory PlanItem.fromJson(Map<String, dynamic> json) =>
      _$PlanItemFromJson(json);
}

@freezed
abstract class TodaysPlan with _$TodaysPlan {
  const factory TodaysPlan({
    @Default(0) int done,
    @Default(0) int total,
    @Default(<PlanItem>[]) List<PlanItem> items,
  }) = _TodaysPlan;

  factory TodaysPlan.fromJson(Map<String, dynamic> json) =>
      _$TodaysPlanFromJson(json);
}

/// A "Continue learning" card.
@freezed
abstract class ContinueItem with _$ContinueItem {
  const factory ContinueItem({
    required String topicId,
    required String title,
    @Default('') String unitCode,
    @Default(0) double progress, // 0-1 or 0-100
  }) = _ContinueItem;

  factory ContinueItem.fromJson(Map<String, dynamic> json) =>
      _$ContinueItemFromJson(json);
}

/// `GET /home/summary`
@freezed
abstract class HomeSummary with _$HomeSummary {
  const factory HomeSummary({
    @Default('') String greetingName,
    @Default('') String initials,
    @Default(0) int streakDays,
    int? daysToExam, // null hides the chip
    NextBestAction? nextBestAction,
    @Default(TodaysPlan()) TodaysPlan todaysPlan,
    @Default(0) double overallMastery, // 0-1 or 0-100
    @Default(0) double masteryChangeWeek, // percentage points, e.g. 4 or -2
    @Default(<ContinueItem>[]) List<ContinueItem> continueLearning,
  }) = _HomeSummary;

  factory HomeSummary.fromJson(Map<String, dynamic> json) =>
      _$HomeSummaryFromJson(json);
}

/// 62 or 0.62 -> 0.62
double asFraction(double value) => value > 1 ? value / 100 : value;

/// Good morning (5-11), Good afternoon (12-16), Good evening (17-4).
String greetingFor(DateTime time) {
  final h = time.hour;
  if (h >= 5 && h < 12) return 'Good morning';
  if (h >= 12 && h < 17) return 'Good afternoon';
  return 'Good evening';
}
