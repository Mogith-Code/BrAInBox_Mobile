import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_page.dart';
import '../domain/knowledge_base_models.dart';

/// Model answers (admin). Only this layer calls the API.
abstract interface class KnowledgeBaseRepository {
  /// `GET /admin/model-answers?status=` (last changed first, max 200).
  Future<List<ModelAnswer>> answers({ReviewStatus? status});

  /// `POST /admin/model-answers`.
  Future<ModelAnswer> create(NewModelAnswer answer);

  /// `PUT /admin/model-answers/{id}/keywords` with
  /// `{points: [{point_id, keywords}]}`; other points keep theirs.
  Future<ModelAnswer> setKeywords(
    String answerId,
    Map<String, List<String>> keywordsByPoint,
  );

  /// Structured and essay questions (`GET /admin/questions?type=`).
  Future<List<WrittenQuestion>> writtenQuestions();
}

class ApiKnowledgeBaseRepository implements KnowledgeBaseRepository {
  ApiKnowledgeBaseRepository(this.api);

  final ApiClient api;

  @override
  Future<List<ModelAnswer>> answers({ReviewStatus? status}) async => [
    for (final e in await api.get<List<dynamic>>(
      '/admin/model-answers',
      query: {if (status != null) 'status': status.apiValue},
    ))
      ModelAnswer.fromJson(Map<String, dynamic>.from(e as Map)),
  ];

  @override
  Future<ModelAnswer> create(NewModelAnswer answer) async =>
      ModelAnswer.fromJson(
        await api.post<Map<String, dynamic>>(
          '/admin/model-answers',
          data: answer.toJson(),
        ),
      );

  @override
  Future<ModelAnswer> setKeywords(
    String answerId,
    Map<String, List<String>> keywordsByPoint,
  ) async => ModelAnswer.fromJson(
    await api.put<Map<String, dynamic>>(
      '/admin/model-answers/$answerId/keywords',
      data: {
        'points': [
          for (final MapEntry(:key, :value) in keywordsByPoint.entries)
            {'point_id': key, 'keywords': value},
        ],
      },
    ),
  );

  @override
  Future<List<WrittenQuestion>> writtenQuestions() async {
    Future<List<WrittenQuestion>> ofType(String type) async {
      final json = await api.get<Map<String, dynamic>>(
        '/admin/questions',
        query: {'type': type, 'page_size': 100},
      );
      return [
        for (final e in json['items'] as List? ?? const [])
          WrittenQuestion.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    }

    final both = await Future.wait([ofType('structured'), ofType('essay')]);
    return [...both[0], ...both[1]];
  }
}

/// DEBUG ONLY (`USE_FAKE_API=true`), also used by the tests.
class FakeKnowledgeBaseRepository implements KnowledgeBaseRepository {
  final created = <NewModelAnswer>[];
  final keywordSaves = <(String, Map<String, List<String>>)>[];

  final _rows = <ModelAnswer>[
    ModelAnswer(
      id: 'a1',
      questionId: 'q4830',
      questionCode: 'Q-4830',
      questionStem: 'Explain the role of ADH in water reabsorption.',
      answerText:
          'ADH is released by the posterior pituitary when blood water '
          'potential falls. It makes the collecting duct walls more '
          'permeable to water, so more water is reabsorbed.',
      totalMarks: 4,
      source: 'marking_scheme',
      status: ReviewStatus.approved,
      points: const [
        AnswerPoint(
          id: 'p1',
          text: 'Released by the posterior pituitary',
          keywords: ['posterior pituitary'],
        ),
        AnswerPoint(
          id: 'p2',
          text: 'When blood water potential falls / osmoreceptors',
          keywords: ['water potential', 'osmoreceptors'],
        ),
        AnswerPoint(
          id: 'p3',
          text: 'Collecting duct becomes more permeable (aquaporins)',
          marks: 2,
          keywords: ['collecting duct', 'aquaporin', 'permeable'],
        ),
      ],
      updatedAt: DateTime(2026, 10, 6),
    ),
    ModelAnswer(
      id: 'a2',
      questionId: 'q4841',
      questionCode: 'Q-4841',
      questionStem: 'Describe how linkage affects dihybrid ratios.',
      answerText:
          'Linked genes are on the same chromosome and tend to be '
          'inherited together...',
      totalMarks: 0,
      source: 'ai',
      status: ReviewStatus.draft,
      updatedAt: DateTime(2026, 10, 7),
    ),
  ];

  final _questions = const [
    WrittenQuestion(
      id: 'q4830',
      code: 'Q-4830',
      stem: 'Explain the role of ADH in water reabsorption.',
      type: 'structured',
    ),
    WrittenQuestion(
      id: 'q4841',
      code: 'Q-4841',
      stem: 'Describe how linkage affects dihybrid ratios.',
      type: 'essay',
    ),
    WrittenQuestion(
      id: 'q4850',
      code: 'Q-4850',
      stem: 'Outline the light-independent reactions of photosynthesis.',
      type: 'structured',
    ),
  ];

  @override
  Future<List<ModelAnswer>> answers({ReviewStatus? status}) async => [
    for (final r in _rows)
      if (status == null || r.status == status) r,
  ];

  @override
  Future<ModelAnswer> create(NewModelAnswer answer) async {
    if (_rows.any((r) => r.questionId == answer.questionId)) {
      throw const ApiException(
        code: 'MODEL_ANSWER_EXISTS',
        message: 'This question already has a model answer.',
        statusCode: 409,
      );
    }
    created.add(answer);
    final q = _questions.firstWhere((q) => q.id == answer.questionId);
    final row = ModelAnswer(
      id: 'a${_rows.length + 1}',
      questionId: q.id,
      questionCode: q.code,
      questionStem: q.stem,
      answerText: answer.answerText,
      totalMarks: answer.points.fold(0, (sum, p) => sum + p.marks),
      source: answer.source.apiValue,
      status: answer.approve ? ReviewStatus.approved : ReviewStatus.draft,
      points: [
        for (final (i, p) in answer.points.indexed)
          AnswerPoint(
            id: 'new-p$i',
            text: p.text,
            marks: p.marks,
            keywords: p.keywords,
          ),
      ],
      updatedAt: DateTime(2026, 10, 7, 12),
    );
    _rows.insert(0, row);
    return row;
  }

  @override
  Future<ModelAnswer> setKeywords(
    String answerId,
    Map<String, List<String>> keywordsByPoint,
  ) async {
    keywordSaves.add((answerId, keywordsByPoint));
    final i = _rows.indexWhere((r) => r.id == answerId);
    final row = _rows[i];
    return _rows[i] = row.withPoints([
      for (final p in row.points)
        keywordsByPoint.containsKey(p.id)
            ? p.withKeywords(keywordsByPoint[p.id]!)
            : p,
    ]);
  }

  @override
  Future<List<WrittenQuestion>> writtenQuestions() async => _questions;
}

final knowledgeBaseRepositoryProvider = Provider<KnowledgeBaseRepository>(
  (ref) => Env.useFakeApi
      ? FakeKnowledgeBaseRepository()
      : ApiKnowledgeBaseRepository(ref.watch(apiClientProvider)),
);
