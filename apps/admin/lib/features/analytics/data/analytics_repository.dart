import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/analytics_models.dart';

part 'analytics_repository.g.dart';

/// Analytics (admin). Uses the backend's `/admin/analytics/*` (built).
abstract interface class AnalyticsRepository {
  Future<AnalyticsData> load(int days);
}

class ApiAnalyticsRepository implements AnalyticsRepository {
  ApiAnalyticsRepository(this.api);

  final ApiClient api;

  Future<Map<String, dynamic>> _get(String part, int days) =>
      api.get<Map<String, dynamic>>(
        '/admin/analytics/$part',
        query: {'days': days},
      );

  @override
  Future<AnalyticsData> load(int days) async {
    final results = await Future.wait([
      _get('overview', days),
      _get('performance', days),
      _get('ai-usage', days),
    ]);
    return (
      overview: AnalyticsOverview.fromJson(results[0]),
      performance: AnalyticsPerformance.fromJson(results[1]),
      ai: AnalyticsAiUsage.fromJson(results[2]),
    );
  }
}

/// DEBUG ONLY (`USE_FAKE_API=true`): numbers like the Figma page.
class FakeAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<AnalyticsData> load(int days) async {
    final today = DateTime(2026, 10, 7);
    return (
      overview: AnalyticsOverview(
        days: days,
        totalStudents: 3105,
        activeStudents: 2280,
        activeStudentsPrevious: 1869,
        activeChangePercent: 22,
        dailyActiveStudents: [
          for (var i = days - 1; i >= 0; i--)
            DailyCount(
              day: today.subtract(Duration(days: i)),
              count: 1700 + (days - i) * 18 + (i % 5) * 40,
            ),
        ],
      ),
      performance: const AnalyticsPerformance(
        units: [
          UnitAverage(
            unitId: 'u1',
            number: 1,
            title: 'Intro',
            averageMastery: 82,
          ),
          UnitAverage(
            unitId: 'u2',
            number: 2,
            title: 'Cell',
            averageMastery: 71,
          ),
          UnitAverage(
            unitId: 'u3',
            number: 3,
            title: 'Evolution',
            averageMastery: 64,
          ),
          UnitAverage(
            unitId: 'u4',
            number: 4,
            title: 'Plants',
            averageMastery: 58,
          ),
          UnitAverage(
            unitId: 'u5',
            number: 5,
            title: 'Animals',
            averageMastery: 54,
          ),
          UnitAverage(
            unitId: 'u6',
            number: 6,
            title: 'Genetics',
            averageMastery: 41,
          ),
          UnitAverage(
            unitId: 'u7',
            number: 7,
            title: 'Molecular',
            averageMastery: 49,
          ),
          UnitAverage(
            unitId: 'u8',
            number: 8,
            title: 'Environment',
            averageMastery: 67,
          ),
          UnitAverage(unitId: 'u9', number: 9, title: 'Microbes'),
          UnitAverage(
            unitId: 'u10',
            number: 10,
            title: 'Applied',
            averageMastery: 56,
          ),
        ],
        misconceptions: [
          CommonMisconception(
            misconceptionId: 'm1',
            title: 'Linked genes assorting independently',
            timesChosen: 1820,
          ),
          CommonMisconception(
            misconceptionId: 'm2',
            title: 'ADH vs aldosterone',
            timesChosen: 1404,
          ),
          CommonMisconception(
            misconceptionId: 'm3',
            title: 'Calvin cycle needs light',
            timesChosen: 1290,
          ),
          CommonMisconception(
            misconceptionId: 'm4',
            title: 'Mitosis/meiosis stage mix-up',
            timesChosen: 1105,
          ),
        ],
      ),
      ai: const AnalyticsAiUsage(
        totalRequests: 48210,
        images: 2310,
        byFeature: [
          AiFeatureUsage(feature: 'notes', requests: 18320, percent: 38),
          AiFeatureUsage(feature: 'tutor', requests: 13017, percent: 27),
          AiFeatureUsage(feature: 'visuals', requests: 6749, percent: 14),
          AiFeatureUsage(feature: 'evaluation', requests: 5785, percent: 12),
          AiFeatureUsage(feature: 'upload', requests: 4339, percent: 9),
        ],
      ),
    );
  }
}

@Riverpod(keepAlive: true)
AnalyticsRepository analyticsRepository(Ref ref) => Env.useFakeApi
    ? FakeAnalyticsRepository()
    : ApiAnalyticsRepository(ref.watch(apiClientProvider));
