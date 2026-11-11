import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/past_papers_models.dart';

part 'past_papers_repository.g.dart';

/// Past papers & marking schemes (admin). Only this layer calls the API.
abstract interface class PastPapersRepository {
  /// `GET /admin/questions/past-papers`
  Future<List<PastPaper>> papers();

  /// `POST /admin/questions/past-papers` (multipart: `file`, `year`,
  /// `paper_type`, optional `scheme`). Extraction runs as a job.
  Future<PastPaper> upload({
    required List<int> bytes,
    required String fileName,
    required int year,
    required PaperType type,
  });

  /// `GET /admin/questions/past-papers/{id}/questions`
  Future<List<PaperQuestion>> questions(String paperId);

  /// `PUT /admin/questions/past-papers/questions/{id}` with
  /// `{model_answer, keywords}`.
  Future<PaperQuestion> saveAnswer(PaperQuestion question);
}

class ApiPastPapersRepository implements PastPapersRepository {
  ApiPastPapersRepository(this.api);

  final ApiClient api;

  static const _base = '/admin/questions/past-papers';

  @override
  Future<List<PastPaper>> papers() async => [
    for (final j in await api.get<List<dynamic>>(_base))
      PastPaper.fromJson(j as Map<String, dynamic>),
  ];

  @override
  Future<PastPaper> upload({
    required List<int> bytes,
    required String fileName,
    required int year,
    required PaperType type,
  }) async => PastPaper.fromJson(
    await api.uploadBytes<Map<String, dynamic>>(
      _base,
      bytes: bytes,
      fileName: fileName,
      fields: {'year': year, 'paper_type': type.apiValue},
    ),
  );

  @override
  Future<List<PaperQuestion>> questions(String paperId) async => [
    for (final j in await api.get<List<dynamic>>('$_base/$paperId/questions'))
      PaperQuestion.fromJson(j as Map<String, dynamic>),
  ];

  @override
  Future<PaperQuestion> saveAnswer(PaperQuestion q) async =>
      PaperQuestion.fromJson(
        await api.put<Map<String, dynamic>>(
          '$_base/questions/${q.id}',
          data: {'model_answer': q.modelAnswer, 'keywords': q.keywords},
        ),
      );
}

/// DEBUG ONLY (`USE_FAKE_API=true`): the papers from the Figma page.
class FakePastPapersRepository implements PastPapersRepository {
  final _papers = <PastPaper>[
    const PastPaper(
      id: 'p1',
      year: 2024,
      schemeLinked: true,
      extraction: ExtractionStatus.done,
      questionsExtracted: 48,
    ),
    const PastPaper(
      id: 'p2',
      year: 2024,
      paperType: PaperType.paper2Structured,
      schemeLinked: true,
      extraction: ExtractionStatus.done,
      questionsExtracted: 48,
    ),
    const PastPaper(
      id: 'p3',
      year: 2023,
      paperType: PaperType.paper2Structured,
      schemeLinked: true,
      progress: 0.68,
    ),
    const PastPaper(
      id: 'p4',
      year: 2022,
      extraction: ExtractionStatus.done,
      questionsExtracted: 48,
    ),
    const PastPaper(
      id: 'p5',
      year: 2019,
      paperType: PaperType.paper2Structured,
      schemeLinked: true,
      extraction: ExtractionStatus.lowConfidence,
      questionsExtracted: 40,
      lowConfidence: 3,
    ),
    const PastPaper(
      id: 'p6',
      year: 2018,
      schemeLinked: true,
      extraction: ExtractionStatus.done,
      questionsExtracted: 48,
      outdatedSyllabus: true,
    ),
  ];

  final _questions = <String, List<PaperQuestion>>{
    'p5': [
      const PaperQuestion(
        id: 'pq1',
        label: 'Q3 (b)',
        marks: 8,
        text:
            'Explain how antidiuretic hormone (ADH) regulates the water content of blood.',
        ocrConfidence: 0.94,
        modelAnswer:
            'When blood water potential falls, osmoreceptors in the hypothalamus '
            'stimulate the posterior pituitary to release ADH. ADH increases '
            'permeability of the DCT and collecting duct walls by inserting '
            'aquaporins, so more water is reabsorbed...',
        keywords: [
          'ADH',
          'collecting duct',
          'permeability',
          'aquaporins',
          'hypothalamus',
        ],
        suggestedKeywords: ['osmoreceptors', 'posterior pituitary'],
      ),
      const PaperQuestion(
        id: 'pq2',
        label: 'Q3 (c)',
        marks: 6,
        text: 'Describe the counter-current multiplier.',
        ocrConfidence: 0.71,
      ),
    ],
  };

  @override
  Future<List<PastPaper>> papers() async => List.of(_papers);

  @override
  Future<PastPaper> upload({
    required List<int> bytes,
    required String fileName,
    required int year,
    required PaperType type,
  }) async {
    final paper = PastPaper(
      id: 'p${_papers.length + 1}',
      year: year,
      paperType: type,
    );
    _papers.insert(0, paper);
    return paper;
  }

  @override
  Future<List<PaperQuestion>> questions(String paperId) async =>
      _questions[paperId] ?? const [];

  @override
  Future<PaperQuestion> saveAnswer(PaperQuestion q) async {
    for (final list in _questions.values) {
      final i = list.indexWhere((e) => e.id == q.id);
      if (i >= 0) list[i] = q;
    }
    return q;
  }
}

@Riverpod(keepAlive: true)
PastPapersRepository pastPapersRepository(Ref ref) => Env.useFakeApi
    ? FakePastPapersRepository()
    : ApiPastPapersRepository(ref.watch(apiClientProvider));
