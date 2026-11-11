import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/content_review_models.dart';

part 'content_review_repository.g.dart';

/// Content library (admin). Only this layer calls the API.
abstract interface class ContentReviewRepository {
  /// `GET /admin/content?type=&status=&unit=`
  Future<List<ContentItem>> items({
    ContentType? type,
    String? status,
    int? unit,
  });

  /// `POST /admin/content/{id}/approve` or `/reject` with `{note}`.
  Future<ContentItem> review(String id, {required bool approve, String? note});

  /// `PATCH /admin/content/{id}` with `{body_markdown}`.
  Future<ContentItem> edit(String id, String bodyMarkdown);
}

class ApiContentReviewRepository implements ContentReviewRepository {
  ApiContentReviewRepository(this.api);

  final ApiClient api;

  @override
  Future<List<ContentItem>> items({
    ContentType? type,
    String? status,
    int? unit,
  }) async => [
    for (final j in await api.get<List<dynamic>>(
      '/admin/content',
      query: {'type': ?type?.apiValue, 'status': ?status, 'unit': ?unit},
    ))
      ContentItem.fromJson(j as Map<String, dynamic>),
  ];

  @override
  Future<ContentItem> review(
    String id, {
    required bool approve,
    String? note,
  }) async => ContentItem.fromJson(
    await api.post<Map<String, dynamic>>(
      '/admin/content/$id/${approve ? 'approve' : 'reject'}',
      data: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
    ),
  );

  @override
  Future<ContentItem> edit(String id, String bodyMarkdown) async =>
      ContentItem.fromJson(
        await api.patch<Map<String, dynamic>>(
          '/admin/content/$id',
          data: {'body_markdown': bodyMarkdown},
        ),
      );
}

/// DEBUG ONLY (`USE_FAKE_API=true`): the library from the Figma page.
class FakeContentReviewRepository implements ContentReviewRepository {
  final _items = <ContentItem>[
    ContentItem(
      id: 'n1',
      title: 'Nephron structure & function',
      type: ContentType.shortNote,
      syllabusCode: '5.4',
      unitNumber: 5,
      status: 'pending_review',
      isAiGenerated: true,
      model: 'Gemini 2.5 Flash',
      promptVersion: 'notes/short.v2',
      bodyMarkdown:
          '## 1. Overview\nThe nephron is the functional unit of the kidney. '
          'Each kidney has about one million nephrons.\n\n## 2. Key regions\n'
          "- Bowman's capsule — ultrafiltration\n"
          '- PCT — selective reabsorption of glucose, amino acids\n'
          '- Loop of Henle — counter-current multiplier\n'
          '- DCT & collecting duct — ADH-controlled water reabsorption',
      autoCheck:
          '1 term not in NIE glossary ("ultrafiltration" -> syllabus uses '
          '"pressure filtration").',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ContentItem(
      id: 'n2',
      title: 'Dihybrid cross — worked examples',
      syllabusCode: '6.1',
      unitNumber: 6,
      status: 'pending_review',
      isAiGenerated: true,
      bodyMarkdown: 'A dihybrid cross follows two genes at once...',
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ContentItem(
      id: 'd1',
      title: 'Labelled human heart',
      type: ContentType.diagram,
      syllabusCode: '5.2',
      unitNumber: 5,
      status: 'approved',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ContentItem(
      id: 'n3',
      title: 'Enzyme kinetics',
      syllabusCode: '2.3',
      unitNumber: 2,
      bodyMarkdown: 'Draft notes on enzyme kinetics.',
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ContentItem(
      id: 'd2',
      title: 'Meiosis stages',
      type: ContentType.diagram,
      syllabusCode: '2.8',
      unitNumber: 2,
      status: 'rejected',
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  @override
  Future<List<ContentItem>> items({
    ContentType? type,
    String? status,
    int? unit,
  }) async => _items
      .where(
        (i) =>
            (type == null || i.type == type) &&
            (status == null || i.status == status) &&
            (unit == null || i.unitNumber == unit),
      )
      .toList();

  @override
  Future<ContentItem> review(
    String id, {
    required bool approve,
    String? note,
  }) async => _replace(
    id,
    (i) => i.copyWith(status: approve ? 'approved' : 'rejected'),
  );

  @override
  Future<ContentItem> edit(String id, String bodyMarkdown) async =>
      _replace(id, (i) => i.copyWith(bodyMarkdown: bodyMarkdown));

  ContentItem _replace(String id, ContentItem Function(ContentItem) change) {
    final i = _items.indexWhere((e) => e.id == id);
    return _items[i] = change(_items[i]).copyWith(updatedAt: DateTime.now());
  }
}

@Riverpod(keepAlive: true)
ContentReviewRepository contentReviewRepository(Ref ref) => Env.useFakeApi
    ? FakeContentReviewRepository()
    : ApiContentReviewRepository(ref.watch(apiClientProvider));
