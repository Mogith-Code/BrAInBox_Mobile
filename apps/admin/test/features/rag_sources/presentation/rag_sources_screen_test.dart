import 'package:brainbox_admin/features/rag_sources/data/rag_sources_repository.dart';
import 'package:brainbox_admin/features/rag_sources/domain/rag_sources_models.dart';
import 'package:brainbox_admin/features/rag_sources/presentation/rag_sources_screen.dart';
import 'package:brainbox_admin/widgets/pick_upload.dart';
import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Empty extends FakeRagSourcesRepository {
  @override
  Future<List<RagSource>> sources() async => [];
}

class _Broken extends FakeRagSourcesRepository {
  @override
  Future<List<RagSource>> sources() async => throw const ApiException(
    code: 'http_500',
    message: 'Something went wrong. Please try again.',
    statusCode: 500,
  );
}

Future<void> _pump(WidgetTester tester, FakeRagSourcesRepository repo) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ragSourcesRepositoryProvider.overrideWithValue(repo),
        pickUploadProvider.overrideWithValue(
          (_) async => const PickedUpload(name: 'guide.pdf', bytes: [1, 2, 3]),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: RagSourcesScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('reads RagSourceOut', () {
    final s = RagSource.fromJson({
      'id': 'd1',
      'title': 'Syllabus',
      'source_type': 'teacher_guide',
      'unit_number': null,
      'year': 2017,
      'status': 'ingesting',
      'chunk_count': 0,
      'page_count': null,
      'error_message': null,
      'indexed_at': null,
      'updated_at': '2026-10-07T09:00:00Z',
    });
    expect(s.status, RagSourceStatus.ingesting);
    expect(s.status.isWorking, isTrue);
    expect(RagSourceType.labelOf(s.sourceType), "Teacher's guide");
    expect(s.indexedAt, isNull);
    expect(
      RagJob.fromJson({'job_id': 'j', 'document_id': null}).documentId,
      isNull,
    );
  });

  testWidgets('lists sources with status, chunks and errors', (tester) async {
    await _pump(tester, FakeRagSourcesRepository());

    expect(find.text('A/L Biology syllabus (NIE, 2017 revision)'), findsOne);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Ingesting'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('412'), findsOneWidget);
    expect(
      find.text('The PDF has no text layer (scanned pages).'),
      findsOneWidget,
    );
    expect(find.text('3 documents · 412 chunks ready'), findsOneWidget);
  });

  testWidgets('re-indexes one document', (tester) async {
    final repo = FakeRagSourcesRepository();
    await _pump(tester, repo);

    // The ingesting row's button is disabled, so the first is the ready one.
    await tester.tap(find.widgetWithText(TextButton, 'Re-index').first);
    await tester.pumpAndSettle();

    expect(repo.reindexed, ['s1']);
    expect(
      find.text('Re-indexing "A/L Biology syllabus (NIE, 2017 revision)".'),
      findsOneWidget,
    );
  });

  testWidgets('re-index all asks first, then sends no id', (tester) async {
    final repo = FakeRagSourcesRepository();
    await _pump(tester, repo);

    await tester.tap(find.text('Re-index all'));
    await tester.pumpAndSettle();
    expect(find.text('Re-index every document?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Re-index all'));
    await tester.pumpAndSettle();

    expect(repo.reindexed, [null]);
  });

  testWidgets('uploads a file and shows the new row', (tester) async {
    final repo = FakeRagSourcesRepository();
    await _pump(tester, repo);

    await tester.tap(find.text('Upload source'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a file to upload.'), findsOneWidget);

    await tester.tap(find.text('Choose file (PDF, DOCX, TXT, MD)'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'guide'),
      'Unit 6 guide',
    );
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(repo.uploads.single.$1.title, 'Unit 6 guide');
    expect(repo.uploads.single.$2, 'guide.pdf');
    expect(find.text('Unit 6 guide'), findsOneWidget);
    expect(find.text('Ready'), findsNWidgets(2));
  });

  testWidgets('empty list explains what to upload', (tester) async {
    await _pump(tester, _Empty());

    expect(find.text('No source documents yet'), findsOneWidget);
  });

  testWidgets('a failed load offers Retry', (tester) async {
    await _pump(tester, _Broken());

    expect(find.byType(ErrorBanner), findsOneWidget);
  });
}
