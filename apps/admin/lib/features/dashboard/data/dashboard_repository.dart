import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/dashboard_models.dart';

part 'dashboard_repository.g.dart';

/// Data layer for the Dashboard feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class DashboardRepository {
  DashboardRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Dashboard screen.
  Future<DashboardSummary> fetchSummary() async {
    // TODO(samni): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/admin/dashboard');
    // return DashboardSummary.fromJson(json);
    return sampleSummary;
  }

  /// Sample figures copied from the Figma mock, so the screen can be built
  /// before the API exists. NOT real data - [DashboardSummary.message] says so
  /// on screen.
  static const sampleSummary = DashboardSummary(
    title: 'Dashboard',
    message: 'Placeholder data - API not connected yet.',
    batchLabel: 'A/L 2027 batch',
    kpis: [
      DashboardKpi(
        kind: DashboardKpiKind.students,
        label: 'Active students',
        value: 2418,
        delta: '+8.4% vs last week',
        sparkline: [12, 14, 13, 16, 15, 18, 19, 21],
      ),
      DashboardKpi(
        kind: DashboardKpiKind.quizzes,
        label: 'Quizzes taken today',
        value: 3962,
        delta: '+312 vs yesterday',
        sparkline: [10, 12, 11, 11, 13, 14, 13, 16],
      ),
      DashboardKpi(
        kind: DashboardKpiKind.aiReview,
        label: 'AI items pending review',
        value: 14,
        delta: '5 older than 48h',
        trend: DashboardTrend.warning,
        sparkline: [8, 9, 11, 10, 12, 12, 13, 14],
      ),
      DashboardKpi(
        kind: DashboardKpiKind.reports,
        label: 'Reported posts',
        value: 6,
        delta: '-3 vs yesterday',
        sparkline: [12, 11, 13, 10, 9, 10, 8, 7],
      ),
    ],
    activity: DashboardActivity(
      dayLabels: [
        '24 Sep', '25', '26', '27', '28', '29', '30', //
        '1 Oct', '2', '3', '4', '5', '6', '7',
      ],
      quizzes: [
        2150, 2380, 2290, 2620, 2480, 2210, 2750, //
        2900, 2820, 3150, 3420, 3600, 3962, 3780,
      ],
      notesGenerated: [
        1080, 1120, 1050, 1150, 1100, 1060, 1180, //
        1200, 1150, 1260, 1240, 1300, 1280, 1310,
      ],
    ),
    recentReports: [
      DashboardReport(
        title: 'Wrong answer key',
        subtitle: 'MCQ #4821 · Krebs cycle',
        meta: '12 reports',
        severity: ReportSeverity.high,
      ),
      DashboardReport(
        title: 'Off-topic post',
        subtitle: 'Group · Unit 6 Genetics',
        meta: 'AI flagged',
      ),
      DashboardReport(
        title: 'Unclear diagram',
        subtitle: 'Nephron labelled diagram',
        meta: '4 reports',
      ),
      DashboardReport(
        title: 'Spam link',
        subtitle: 'Post by @kavindu_22',
        meta: '3 reports',
        severity: ReportSeverity.high,
      ),
      DashboardReport(
        title: 'Outdated content',
        subtitle: '2018 Paper · Q14',
        meta: '2 reports',
        severity: ReportSeverity.high,
      ),
    ],
    missedTopicsAttempts: 41208,
    missedTopics: [
      MissedTopic(
        topic: 'Dihybrid crosses & linkage',
        unit: 'Unit 6 · Genetics',
        missRate: 0.64,
        attempts: 1820,
        topMisconception: 'Assumes independent assortment for linked genes',
      ),
      MissedTopic(
        topic: 'Counter-current mechanism',
        unit: 'Unit 5 · Nephron',
        missRate: 0.58,
        attempts: 1404,
        topMisconception: 'Confuses ADH & aldosterone',
      ),
      MissedTopic(
        topic: 'Light-independent reactions',
        unit: 'Unit 2 · Photosynthesis',
        missRate: 0.51,
        attempts: 1290,
        topMisconception: 'Thinks Calvin cycle needs light directly',
      ),
      MissedTopic(
        topic: 'Sex-linked inheritance',
        unit: 'Unit 6 · Genetics',
        missRate: 0.47,
        attempts: 980,
        topMisconception: 'Ignores X-linkage in males',
      ),
    ],
  );
}

@riverpod
DashboardRepository dashboardRepository(Ref ref) =>
    DashboardRepository(ref.watch(apiClientProvider));
