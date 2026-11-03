import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_models.freezed.dart';
part 'dashboard_models.g.dart';

/// Everything the Dashboard screen shows.
///
// TODO(samni): check these fields against the response of
// `GET /admin/dashboard` (see the backend OpenAPI /docs) once it exists.
// Run `melos run gen` after editing.
@freezed
abstract class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    required String title,

    /// A note about the data, e.g. that it is placeholder data. Shown on the
    /// screen when not empty.
    @Default('') String message,

    /// The student batch the numbers are for, e.g. "A/L 2027 batch".
    @Default('') String batchLabel,
    @Default([]) List<DashboardKpi> kpis,
    @Default(DashboardActivity()) DashboardActivity activity,
    @Default([]) List<DashboardReport> recentReports,
    @Default([]) List<MissedTopic> missedTopics,

    /// How many attempts [missedTopics] is based on.
    @Default(0) int missedTopicsAttempts,
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}

/// Which KPI a tile shows. The screen picks the icon and colour from this.
enum DashboardKpiKind { students, quizzes, aiReview, reports }

/// Which way a KPI moved, and whether that is good news.
enum DashboardTrend { good, bad, warning }

/// One KPI tile, e.g. "Active students 2,418, +8.4% vs last week".
@freezed
abstract class DashboardKpi with _$DashboardKpi {
  const factory DashboardKpi({
    required DashboardKpiKind kind,
    required String label,
    required int value,

    /// Short change text, e.g. "+8.4% vs last week" or "5 older than 48h".
    @Default('') String delta,
    @Default(DashboardTrend.good) DashboardTrend trend,

    /// Recent values for the small sparkline, oldest first.
    @Default([]) List<double> sparkline,
  }) = _DashboardKpi;

  factory DashboardKpi.fromJson(Map<String, dynamic> json) =>
      _$DashboardKpiFromJson(json);
}

/// Daily activity for the line chart, oldest day first. All lists have the
/// same length.
@freezed
abstract class DashboardActivity with _$DashboardActivity {
  const factory DashboardActivity({
    /// X-axis label per day, e.g. "24 Sep".
    @Default([]) List<String> dayLabels,
    @Default([]) List<int> quizzes,
    @Default([]) List<int> notesGenerated,
  }) = _DashboardActivity;

  factory DashboardActivity.fromJson(Map<String, dynamic> json) =>
      _$DashboardActivityFromJson(json);
}

/// How urgent a report is.
enum ReportSeverity { high, medium }

/// One row of "Recent reports".
@freezed
abstract class DashboardReport with _$DashboardReport {
  const factory DashboardReport({
    required String title,

    /// Where it was reported, e.g. "MCQ #4821 · Krebs cycle".
    @Default('') String subtitle,

    /// e.g. "12 reports" or "AI flagged".
    @Default('') String meta,
    @Default(ReportSeverity.medium) ReportSeverity severity,
  }) = _DashboardReport;

  factory DashboardReport.fromJson(Map<String, dynamic> json) =>
      _$DashboardReportFromJson(json);
}

/// One row of "Most-missed topics".
@freezed
abstract class MissedTopic with _$MissedTopic {
  const factory MissedTopic({
    required String topic,
    required String unit,

    /// 0.0 - 1.0
    required double missRate,
    required int attempts,
    @Default('') String topMisconception,
  }) = _MissedTopic;

  factory MissedTopic.fromJson(Map<String, dynamic> json) =>
      _$MissedTopicFromJson(json);
}
