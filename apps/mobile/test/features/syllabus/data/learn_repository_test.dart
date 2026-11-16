import 'dart:convert';
import 'dart:typed_data';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/syllabus/data/api_learn_repository.dart';
import 'package:brainbox_mobile/features/syllabus/data/learn_repository.dart';
import 'package:brainbox_mobile/features/syllabus/data/mock_learn_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request from [routes] (`'GET /learn/subjects'` -> body)
/// and records what was asked.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Object?)> routes;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = '${options.method} ${options.uri.path}';
    final (status, body) =
        routes[key] ?? (404, {'detail': 'Not found', 'code': 'NOT_FOUND'});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiLearnRepository _api(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiLearnRepository(
    ApiClient(dio: dio, getIdToken: ({forceRefresh = false}) async => 'token'),
  );
}

void main() {
  group('MockLearnRepository', () {
    late MockLearnRepository repo;

    setUp(
      () =>
          repo = MockLearnRepository(latency: Duration.zero, pollsUntilDone: 2),
    );

    test('seeds 10 Biology units with the backend topic counts', () async {
      final subjects = await repo.fetchSubjects();
      expect(subjects.where((s) => s.available).single.id, 'biology');

      final units = await repo.fetchUnits('biology');
      expect(units, hasLength(10));
      expect(units.map((u) => u.topicCount), [
        4,
        14,
        11,
        12,
        18,
        9,
        9,
        8,
        7,
        6,
      ]);
      for (final u in units) {
        expect(seedTopics[u.id], hasLength(u.topicCount), reason: u.title);
      }
      expect(await repo.fetchUnits('chemistry'), isEmpty);
    });

    test('Genetics: 9 topics, 2 mastered, 3 weak', () async {
      final unit = await repo.fetchUnit('unit-6');
      expect(unit.topics.map((t) => t.title).first, 'Mendelian inheritance');
      expect(unit.topics, hasLength(9));
      expect(unit.masteredCount, 2);
      expect(unit.weakCount, 3);
    });

    test(
      'Mendelian inheritance has a full note with every block type',
      () async {
        final note = await repo.fetchNote('t-mendelian', NoteType.full);
        final types = note!.blocks.map((b) => b.runtimeType).toSet();
        expect(
          types,
          containsAll([
            HeadingBlock,
            ParagraphBlock,
            DefinitionBlock,
            TipBlock,
            BulletListBlock,
            TableBlock,
          ]),
        );
        expect(await repo.fetchNote('t-mendelian', NoteType.short), isNull);
      },
    );

    test('bookmarks add, list and remove', () async {
      await repo.addBookmark('t-mendelian');
      expect(
        (await repo.fetchBookmarks()).map((b) => b.topicId),
        contains('t-mendelian'),
      );
      expect((await repo.fetchTopic('t-mendelian')).saved, isTrue);

      await repo.removeBookmark('t-mendelian');
      expect(
        (await repo.fetchBookmarks()).map((b) => b.topicId),
        isNot(contains('t-mendelian')),
      );
    });

    test(
      'generation job: queued -> running -> done, then the note exists',
      () async {
        final id = await repo.startNoteGeneration(
          't-pedigree',
          const NoteGenerationRequest(type: NoteType.short),
        );
        expect((await repo.fetchJob(id)).status, JobStatus.queued);
        final done = await repo.fetchJob(id);
        expect(done.status, JobStatus.done);
        expect(done.resultId, isNotNull);
        final note = await repo.fetchNote('t-pedigree', NoteType.short);
        expect(note!.aiGenerated, isTrue);
        expect(note.blocks.whereType<BulletListBlock>(), isNotEmpty);
      },
    );

    test('failNextGeneration makes the job fail with a message', () async {
      repo.failNextGeneration = true;
      final id = await repo.startNoteGeneration(
        't-pedigree',
        const NoteGenerationRequest(),
      );
      await repo.fetchJob(id);
      final job = await repo.fetchJob(id);
      expect(job.status, JobStatus.failed);
      expect(job.error, isNotEmpty);
    });

    test(
      'upload -> processing -> done with summary; save to short notes',
      () async {
        final progress = <double>[];
        final upload = await repo.createUpload(
          PickedUploadFile(name: 'notes.pdf', bytes: Uint8List(4)),
          topicId: 't-mendelian',
          onProgress: progress.add,
        );
        expect(progress.last, 1);
        expect(upload.status, UploadStatus.processing);
        expect(upload.topic?.title, 'Mendelian inheritance');

        await repo.fetchUpload(upload.id);
        final done = await repo.fetchUpload(upload.id);
        expect(done.status, UploadStatus.done);
        expect(done.summary, isNotEmpty);
        expect(done.keyPoints, isNotEmpty);

        await repo.saveUploadToShortNotes(upload.id);
        final notes = (await repo.fetchBookmarks()).where(
          (b) => b.kind == BookmarkKind.shortNote,
        );
        expect(notes.single.uploadId, upload.id);

        await repo.deleteUpload(upload.id);
        expect(
          (await repo.fetchUploads()).map((u) => u.id),
          isNot(contains(upload.id)),
        );
      },
    );

    test('search matches units and topics', () async {
      final result = await repo.search('cross');
      expect(
        result.topics.map((t) => t.id),
        containsAll(['t-dihybrid', 't-test-cross']),
      );
      expect((await repo.search('genetics')).units.single.id, 'unit-6');
      expect((await repo.search('zzz')).isEmpty, isTrue);
    });

    test('opening a not-started topic makes it in progress', () async {
      expect(
        (await repo.fetchTopic('t-polygenic')).topic.status,
        TopicStatus.notStarted,
      );
      await repo.sendProgress('t-polygenic', ProgressEvent.opened);
      expect(
        (await repo.fetchTopic('t-polygenic')).topic.status,
        TopicStatus.inProgress,
      );
    });
  });

  group('ApiLearnRepository', () {
    test('reads units from {items, total} under /learn, sorted', () async {
      final adapter = _FakeAdapter({
        'GET /api/v1/learn/subjects/biology/units': (
          200,
          {
            'items': [
              {
                'id': 'u2',
                'title': 'Two',
                'order': 2,
                'topic_count': 3,
                'mastery_percent': 50,
                'mastery_level': 'strong',
              },
              {
                'id': 'u1',
                'title': 'One',
                'number': 1,
                'topic_count': 4,
                'mastery_percent': 80,
                'mastery_level': 'mastered',
              },
            ],
            'total': 2,
          },
        ),
      });
      final units = await _api(adapter).fetchUnits('biology');
      expect(units.map((u) => u.id), ['u1', 'u2']);
      expect(units.first.mastery, 0.8);
      expect(units.first.masteryLevel, MasteryLevel.mastered);
      expect(adapter.requests.single.headers['Authorization'], 'Bearer token');
    });

    test('reads a flat unit with topics and counts', () async {
      final adapter = _FakeAdapter({
        'GET /api/v1/learn/units/unit-6': (
          200,
          {
            'id': 'unit-6',
            'title': 'Genetics',
            'order': 6,
            'topic_count': 2,
            'mastery_percent': 42,
            'mastery_level': 'weak',
            'topics': [
              {
                'id': 't1',
                'title': 'A',
                'order': 1,
                'status': 'mastered',
                'progress_percent': 100,
              },
              {
                'id': 't2',
                'title': 'B',
                'order': 2,
                'status': 'in_progress',
                'progress_percent': 40,
                'is_weak': true,
              },
            ],
            'counts': {'mastered': 1, 'weak': 1},
          },
        ),
      });
      final unit = await _api(adapter).fetchUnit('unit-6');
      expect(unit.unit.title, 'Genetics');
      expect(unit.topics.last.isWeak, isTrue);
      expect(unit.topics.last.progress, 0.4);
      expect(unit.topics.last.unitId, 'unit-6');
      expect(unit.masteredCount, 1);
      expect(unit.weakCount, 1);
    });

    test(
      'reads topic detail with breadcrumb, bookmark and syllabus flags',
      () async {
        final adapter = _FakeAdapter({
          'GET /api/v1/learn/topics/t1': (
            200,
            {
              'id': 't1',
              'title': 'Mendelian inheritance',
              'unit_id': 'unit-6',
              'unit_order': 6,
              'status': 'in_progress',
              'mastery_level': 'improving',
              'breadcrumb': ['Biology', 'Unit 6', 'Mendelian inheritance'],
              'is_bookmarked': true,
              'syllabus_version': 2017,
              'is_outdated': true,
              'syllabus_code': '6.1',
            },
          ),
        });
        final topic = await _api(adapter).fetchTopic('t1');
        expect(
          topic.breadcrumbText,
          'Biology › Unit 6 › Mendelian inheritance',
        );
        expect(topic.saved, isTrue);
        expect(topic.isOutdated, isTrue);
        expect(topic.syllabusVersion, '2017');
        expect(topic.syllabusTagText, 'Unit 6 · 6.1 Mendelian inheritance');
      },
    );

    test('notes: blocks are parsed; 404 means no notes yet', () async {
      final adapter = _FakeAdapter({
        'GET /api/v1/learn/topics/t1/notes': (
          200,
          {
            'id': 'n1',
            'type': 'full',
            'read_minutes': 6,
            'ai_generated': true,
            'blocks': [
              {'type': 'heading', 'text': 'H'},
              {
                'type': 'paragraph',
                'text': 'P',
                'highlights': ['P'],
              },
              {
                'type': 'bullet_list',
                'items': ['a'],
              },
              {'type': 'image', 'image_url': 'https://x/y.png'},
              {'type': 'video_embed'},
            ],
          },
        ),
      });
      final api = _api(adapter);
      final note = await api.fetchNote('t1', NoteType.full);
      expect(adapter.requests.last.queryParameters['type'], 'full');
      expect(note!.blocks[2], isA<BulletListBlock>());
      expect((note.blocks[3] as ImageBlock).url, 'https://x/y.png');
      expect(note.blocks[4], isA<UnknownBlock>());
      expect(await api.fetchNote('t2', NoteType.short), isNull);
    });

    test('generation posts the options and polls /learn/jobs', () async {
      final adapter = _FakeAdapter({
        'POST /api/v1/learn/topics/t1/notes/generate': (202, {'job_id': 'j1'}),
        'GET /api/v1/learn/jobs/j1': (
          200,
          {'status': 'done', 'result_id': 'n9'},
        ),
      });
      final api = _api(adapter);
      final id = await api.startNoteGeneration(
        't1',
        const NoteGenerationRequest(
          type: NoteType.short,
          depth: NoteDepth.quick,
          includeExamples: false,
        ),
      );
      expect(id, 'j1');
      expect(adapter.requests.first.data, {
        'type': 'short',
        'depth': 'quick',
        'include_examples': false,
        'include_past_paper_tips': true,
      });
      final job = await api.fetchJob('j1');
      expect(job.status, JobStatus.done);
      expect(job.resultId, 'n9');
    });

    test('errors in the {detail, code} shape become ApiException', () async {
      final adapter = _FakeAdapter({
        'DELETE /api/v1/learn/bookmarks/t1': (
          409,
          {'detail': 'Already removed', 'code': 'NOT_BOOKMARKED'},
        ),
      });
      await expectLater(
        _api(adapter).removeBookmark('t1'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'NOT_BOOKMARKED'),
        ),
      );
    });

    test('upload sends multipart with topic and summary length', () async {
      final adapter = _FakeAdapter({
        'POST /api/v1/learn/uploads': (
          201,
          {'upload_id': 'up1', 'status': 'processing'},
        ),
      });
      final upload = await _api(adapter).createUpload(
        PickedUploadFile(name: 'n.pdf', bytes: Uint8List.fromList([1, 2])),
        topicId: 't1',
        summaryLength: SummaryLength.short,
      );
      expect(upload.id, 'up1');
      expect(upload.fileName, 'n.pdf');
      expect(upload.status, UploadStatus.processing);
      final form = adapter.requests.single.data as FormData;
      expect(Map.fromEntries(form.fields), {
        'topic_id': 't1',
        'summary_length': 'short',
      });
      expect(form.files.single.key, 'file');
    });
  });
}
