import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_models.freezed.dart';
part 'analytics_models.g.dart';

/// The period buttons (7d / 30d / 90d / Term) -> the backend's `?days=`.
enum AnalyticsRange {
  week('7d', 7),
  month('30d', 30),
  quarter('90d', 90),
  term('Term', 120);

  const AnalyticsRange(this.label, this.days);

  final String label;
  final int days;
}

/// `DailyCount`: one day of a chart.
@freezed
abstract class DailyCount with _$DailyCount {
  const factory DailyCount({required DateTime day, @Default(0) int count}) =
      _DailyCount;

  factory DailyCount.fromJson(Map<String, dynamic> json) =>
      _$DailyCountFromJson(json);
}

/// `GET /admin/analytics/overview?days=`
@freezed
abstract class AnalyticsOverview with _$AnalyticsOverview {
  const factory AnalyticsOverview({
    @Default(30) int days,
    @Default(0) int totalStudents,
    @Default(0) int newStudents,
    @Default(0) int activeStudents,
    @Default(0) int activeStudentsPrevious,
    double? activeChangePercent, // null when the period before had none
    @Default(0) int attemptsCompleted,
    @Default(0) int mcqAnswers,
    @Default([]) List<DailyCount> dailyActiveStudents,
  }) = _AnalyticsOverview;

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsOverviewFromJson(json);
}

/// `UnitAverage`
@freezed
abstract class UnitAverage with _$UnitAverage {
  const factory UnitAverage({
    required String unitId,
    required int number,
    required String title,
    double? averageMastery, // null = nobody measured yet (never shown as 0 %)
    @Default(0) int studentsAssessed,
  }) = _UnitAverage;

  factory UnitAverage.fromJson(Map<String, dynamic> json) =>
      _$UnitAverageFromJson(json);
}

/// `CommonMisconception`
@freezed
abstract class CommonMisconception with _$CommonMisconception {
  const factory CommonMisconception({
    required String misconceptionId,
    required String title,
    @Default(0) int timesChosen,
    @Default(0) int students,
  }) = _CommonMisconception;

  factory CommonMisconception.fromJson(Map<String, dynamic> json) =>
      _$CommonMisconceptionFromJson(json);
}

/// `GET /admin/analytics/performance?days=` (only what this page shows).
@freezed
abstract class AnalyticsPerformance with _$AnalyticsPerformance {
  const factory AnalyticsPerformance({
    @Default([]) List<UnitAverage> units,
    @Default([]) List<CommonMisconception> misconceptions,
  }) = _AnalyticsPerformance;

  factory AnalyticsPerformance.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsPerformanceFromJson(json);
}

/// `AIFeatureUsage`
@freezed
abstract class AiFeatureUsage with _$AiFeatureUsage {
  const factory AiFeatureUsage({
    required String feature, // "notes", "visuals", "embed"...
    @Default(0) int requests,
    @Default(0) double percent,
  }) = _AiFeatureUsage;

  factory AiFeatureUsage.fromJson(Map<String, dynamic> json) =>
      _$AiFeatureUsageFromJson(json);
}

/// `GET /admin/analytics/ai-usage?days=`
@freezed
abstract class AnalyticsAiUsage with _$AnalyticsAiUsage {
  const factory AnalyticsAiUsage({
    @Default(0) int totalRequests,
    @Default(0) int images,
    double? totalCostUsd,
    @JsonKey(name: 'by_feature') @Default([]) List<AiFeatureUsage> byFeature,
    @Default([]) List<DailyCount> dailyRequests,
  }) = _AnalyticsAiUsage;

  factory AnalyticsAiUsage.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsAiUsageFromJson(json);
}

/// Everything the Analytics page shows for one range.
typedef AnalyticsData = ({
  AnalyticsOverview overview,
  AnalyticsPerformance performance,
  AnalyticsAiUsage ai,
});
