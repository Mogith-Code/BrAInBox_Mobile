import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/question_bank_models.dart';

part 'question_bank_repository.g.dart';

/// Question bank (admin). Only this layer calls the API.
abstract interface class QuestionBankRepository {
  /// `GET /admin/questions?unit=&type=&difficulty=&status=&page=&page_size=`
  Future<QuestionPage> questions(QuestionFilter filter);

  /// `POST /admin/questions/bulk` with `{ids, action}`.
  Future<void> bulk(List<String> ids, BulkAction action);

  /// `GET /admin/questions/{id}`
  Future<QuestionDetail> question(String id);

  /// `POST /admin/questions` (new) or `PUT /admin/questions/{id}`.
  Future<QuestionDetail> save(QuestionDetail question);
}

class ApiQuestionBankRepository implements QuestionBankRepository {
  ApiQuestionBankRepository(this.api);

  final ApiClient api;

  @override
  Future<QuestionPage> questions(QuestionFilter filter) async =>
      QuestionPage.fromJson(
        await api.get<Map<String, dynamic>>(
          '/admin/questions',
          query: filter.toQuery(),
        ),
      );

  @override
  Future<void> bulk(List<String> ids, BulkAction action) => api.post<Object?>(
    '/admin/questions/bulk',
    data: {'ids': ids, 'action': action.apiValue},
  );

  @override
  Future<QuestionDetail> question(String id) async => QuestionDetail.fromJson(
    await api.get<Map<String, dynamic>>('/admin/questions/$id'),
  );

  @override
  Future<QuestionDetail> save(QuestionDetail question) async {
    final body = question.toJson()
      ..removeWhere((k, _) => k == 'id' || k == 'code');
    final json = question.id == null
        ? await api.post<Map<String, dynamic>>('/admin/questions', data: body)
        : await api.put<Map<String, dynamic>>(
            '/admin/questions/${question.id}',
            data: body,
          );
    return QuestionDetail.fromJson(json);
  }
}

/// DEBUG ONLY (`USE_FAKE_API=true`): the rows from the Figma page.
class FakeQuestionBankRepository implements QuestionBankRepository {
  final _rows = <QuestionRow>[
    const QuestionRow(
      id: 'q4821',
      code: 'Q-4821',
      stem: 'In the Krebs cycle, which step releases CO₂ first?',
      unitNumber: 2,
      topicTitle: 'Respiration',
      sourceYear: 2019,
      status: 'approved',
    ),
    const QuestionRow(
      id: 'q4822',
      code: 'Q-4822',
      stem: 'A dihybrid test cross yields 1:1:1:1. What does this show?',
      unitNumber: 6,
      topicTitle: 'Mendelian',
      difficulty: Difficulty.hard,
      isAiGenerated: true,
      status: 'pending_review',
    ),
    const QuestionRow(
      id: 'q4830',
      code: 'Q-4830',
      stem: 'Explain the role of ADH in water reabsorption.',
      unitNumber: 5,
      topicTitle: 'Excretion',
      type: QuestionKind.structured,
      sourceYear: 2022,
      status: 'approved',
    ),
    const QuestionRow(
      id: 'q4835',
      code: 'Q-4835',
      stem: 'Which structure is absent in prokaryotic cells?',
      unitNumber: 2,
      topicTitle: 'Cell',
      difficulty: Difficulty.easy,
      sourceYear: 2016,
      status: 'approved',
    ),
    const QuestionRow(
      id: 'q4841',
      code: 'Q-4841',
      stem: 'Describe how linkage affects dihybrid ratios.',
      unitNumber: 6,
      topicTitle: 'Deviations',
      type: QuestionKind.essay,
      difficulty: Difficulty.hard,
      isAiGenerated: true,
      status: 'pending_review',
    ),
    const QuestionRow(
      id: 'q4843',
      code: 'Q-4843',
      stem: 'Identify the hormone that promotes stem elongation.',
      unitNumber: 4,
      topicTitle: 'Hormones',
      difficulty: Difficulty.easy,
      sourceYear: 2020,
    ),
    const QuestionRow(
      id: 'q4856',
      code: 'Q-4856',
      stem: 'Which blood group allele is recessive?',
      unitNumber: 6,
      topicTitle: 'Deviations',
      difficulty: Difficulty.easy,
      sourceYear: 2014,
      status: 'rejected',
    ),
  ];

  final _details = <String, QuestionDetail>{
    'q4822': const QuestionDetail(
      id: 'q4822',
      code: 'Q-4822',
      stem:
          'Genes A and B are on the same chromosome, 8 map units apart. A test '
          'cross is done with AaBb (AB/ab). Which offspring ratio is most likely?',
      difficulty: Difficulty.hard,
      isAiGenerated: true,
      status: 'pending_review',
      // Ids from FakeSyllabusManagerRepository (Unit 6 > 6.2 > Linkage).
      unitId: 'u6',
      topicId: 't6.2',
      conceptId: 'c4',
      explanation:
          'Linked genes are inherited together. With 8 map units, only ~8% of '
          'offspring are recombinant (Ab, aB); 92% are parental (AB, ab).',
      options: [
        OptionDraft(
          label: 'A',
          text: '9 : 3 : 3 : 1',
          misconception: 'Assumes independent assortment for linked genes',
        ),
        OptionDraft(
          label: 'B',
          text: '1 : 1 : 1 : 1',
          misconception: 'Assumes independent assortment for linked genes',
        ),
        OptionDraft(
          label: 'C',
          text: 'Mostly parental types with few recombinants',
          isCorrect: true,
        ),
        OptionDraft(
          label: 'D',
          text: '3 : 1',
          misconception: 'Applies monohybrid ratio to dihybrid cross',
        ),
        OptionDraft(
          label: 'E',
          text: 'Only parental types — no recombinants',
          misconception: 'Forgets recombinants are the minority',
        ),
      ],
    ),
  };

  @override
  Future<QuestionPage> questions(QuestionFilter filter) async {
    final rows = _rows
        .where(
          (r) =>
              (filter.unit == null || r.unitNumber == filter.unit) &&
              (filter.type == null || r.type == filter.type) &&
              (filter.difficulty == null ||
                  r.difficulty == filter.difficulty) &&
              (filter.status == null || r.status == filter.status),
        )
        .toList();
    return QuestionPage(items: rows, total: 8942, pastPaperPercent: 41);
  }

  @override
  Future<void> bulk(List<String> ids, BulkAction action) async {
    for (var i = 0; i < _rows.length; i++) {
      if (!ids.contains(_rows[i].id)) continue;
      if (action == BulkAction.approve) {
        _rows[i] = _rows[i].copyWith(status: 'approved');
      } else if (action == BulkAction.markOutdated) {
        _rows[i] = _rows[i].copyWith(status: 'archived');
      }
    }
    if (action == BulkAction.delete) {
      _rows.removeWhere((r) => ids.contains(r.id));
    }
  }

  @override
  Future<QuestionDetail> question(String id) async =>
      _details[id] ??
      QuestionDetail.blank().copyWith(
        id: id,
        code: _rows.firstWhere((r) => r.id == id).code,
        stem: _rows.firstWhere((r) => r.id == id).stem,
      );

  @override
  Future<QuestionDetail> save(QuestionDetail question) async {
    final id = question.id ?? 'q${9000 + _details.length}';
    return _details[id] = question.copyWith(
      id: id,
      code: question.code ?? 'Q-$id',
    );
  }
}

@Riverpod(keepAlive: true)
QuestionBankRepository questionBankRepository(Ref ref) => Env.useFakeApi
    ? FakeQuestionBankRepository()
    : ApiQuestionBankRepository(ref.watch(apiClientProvider));
