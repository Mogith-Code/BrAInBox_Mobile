import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/quality_review_models.dart';

part 'quality_review_repository.g.dart';

/// Question quality review (admin). Only this layer calls the API.
abstract interface class QualityReviewRepository {
  /// `GET /admin/questions/quality`
  Future<QualityQueue> queue();

  /// `POST /admin/questions/{id}/review` with `{approve}`.
  Future<void> review(String id, {required bool approve});
}

class ApiQualityReviewRepository implements QualityReviewRepository {
  ApiQualityReviewRepository(this.api);

  final ApiClient api;

  @override
  Future<QualityQueue> queue() async => QualityQueue.fromJson(
    await api.get<Map<String, dynamic>>('/admin/questions/quality'),
  );

  @override
  Future<void> review(String id, {required bool approve}) => api.post<Object?>(
    '/admin/questions/$id/review',
    data: {'approve': approve},
  );
}

/// DEBUG ONLY (`USE_FAKE_API=true`): the queue from the Figma page.
class FakeQualityReviewRepository implements QualityReviewRepository {
  static const _names = [
    'Single correct answer',
    'Distractor quality',
    'Syllabus match',
    'Duplicate check',
  ];

  static List<QualityCheck> _checks(
    List<CheckResult> results, [
    Map<int, String> notes = const {},
  ]) => [
    for (var i = 0; i < results.length; i++)
      QualityCheck(
        name: _names[i],
        result: results[i],
        note: notes[i] ?? 'No issues found.',
      ),
  ];

  final _items = <QualityItem>[
    QualityItem(
      id: 'q4822',
      code: 'Q-4822',
      stem: 'Linked genes 8 map units apart — test cross ratio?',
      unitNumber: 6,
      topicCode: '6.2',
      checks: _checks(const [
        CheckResult.pass,
        CheckResult.pass,
        CheckResult.pass,
        CheckResult.pass,
      ]),
    ),
    QualityItem(
      id: 'q4850',
      code: 'Q-4850',
      stem: 'Calculate allele frequency given q² = 0.16.',
      unitNumber: 8,
      topicCode: '8.2',
      checks: _checks(
        const [
          CheckResult.pass,
          CheckResult.review,
          CheckResult.pass,
          CheckResult.pass,
        ],
        {1: 'Two distractors are numerically close.'},
      ),
    ),
    QualityItem(
      id: 'q4877',
      code: 'Q-4877',
      stem: 'Which part of the nephron is impermeable to water?',
      unitNumber: 5,
      topicCode: '5.4',
      checks: _checks(
        const [
          CheckResult.fail,
          CheckResult.pass,
          CheckResult.pass,
          CheckResult.review,
        ],
        {
          0: 'Options B and D could both be correct — PCT and descending limb wording overlaps.',
          3: '91% similar to Q-2210 (2019 Paper I Q23).',
        },
      ),
      studentReports: const [
        StudentReportCount(text: 'I think B is also right', count: 3),
        StudentReportCount(text: 'Diagram missing'),
      ],
    ),
    QualityItem(
      id: 'q4881',
      code: 'Q-4881',
      stem: 'The enzyme that fixes CO₂ in the Calvin cycle is...',
      unitNumber: 2,
      topicCode: '2.6',
      checks: _checks(const [
        CheckResult.pass,
        CheckResult.pass,
        CheckResult.pass,
        CheckResult.pass,
      ]),
    ),
  ];

  @override
  Future<QualityQueue> queue() async => QualityQueue(
    inQueue: _items.length,
    autoCheckFailed: _items
        .where((i) => i.checks.any((c) => c.result == CheckResult.fail))
        .length,
    withStudentReports: _items.where((i) => i.studentReports.isNotEmpty).length,
    avgReviewMinutes: 100,
    items: List.of(_items),
  );

  @override
  Future<void> review(String id, {required bool approve}) async =>
      _items.removeWhere((i) => i.id == id);
}

@Riverpod(keepAlive: true)
QualityReviewRepository qualityReviewRepository(Ref ref) => Env.useFakeApi
    ? FakeQualityReviewRepository()
    : ApiQualityReviewRepository(ref.watch(apiClientProvider));
