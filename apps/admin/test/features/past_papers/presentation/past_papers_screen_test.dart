import 'package:brainbox_admin/features/past_papers/data/past_papers_repository.dart';
import 'package:brainbox_admin/features/past_papers/domain/past_papers_models.dart';
import 'package:brainbox_admin/features/past_papers/presentation/past_papers_screen.dart';
import 'package:brainbox_admin/features/past_papers/application/past_papers_controller.dart';
import 'package:brainbox_admin/widgets/pick_upload.dart';
import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The extraction of an uploaded paper finishes after [readsUntilDone]
/// list reloads; [failUpload] answers like the backend for a duplicate.
class _Extracting extends FakePastPapersRepository {
  _Extracting({this.failUpload = false});

  static const readsUntilDone = 2;
  final bool failUpload;
  int reads = 0;
  final uploads = <(String, int, PaperType)>[];

  @override
  Future<PastPaper> upload({
    required List<int> bytes,
    required String fileName,
    required int year,
    required PaperType type,
  }) async {
    if (failUpload) {
      throw const ApiException(
        code: 'PAST_PAPER_EXISTS',
        message: 'The 2024 Paper II is already uploaded',
        statusCode: 409,
      );
    }
    uploads.add((fileName, year, type));
    return super.upload(
      bytes: bytes,
      fileName: fileName,
      year: year,
      type: type,
    );
  }

  @override
  Future<List<PastPaper>> papers() async {
    final all = await super.papers();
    if (uploads.isEmpty) return all;
    reads++;
    return [
      for (final p in all)
        p.extraction == ExtractionStatus.running && reads >= readsUntilDone
            ? p.copyWith(
                extraction: ExtractionStatus.done,
                questionsExtracted: 37,
                progress: 1,
              )
            : p,
    ];
  }
}

Future<T> _pump<T extends FakePastPapersRepository>(
  WidgetTester tester, [
  T? given,
]) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = given ?? FakePastPapersRepository() as T;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pastPapersRepositoryProvider.overrideWithValue(repo),
        pickUploadProvider.overrideWithValue(
          (_) async => const PickedUpload(name: 'al-2024-p2.pdf', bytes: [1]),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: PastPapersScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  test('reads the paper type and extraction status', () {
    final paper = PastPaper.fromJson({
      'id': 'p',
      'year': 2019,
      'paper_type': 'paper_2_structured',
      'extraction': 'low_confidence',
      'low_confidence': 3,
    });
    expect(paper.paperType, PaperType.paper2Structured);
    expect(paper.extraction, ExtractionStatus.lowConfidence);
  });

  testWidgets('shows papers with their extraction state', (tester) async {
    await _pump(tester);

    expect(find.text('Past papers & marking schemes'), findsOneWidget);
    expect(find.text('✓ 48 questions extracted'), findsNWidgets(4));
    expect(find.text('Extracting · 68%'), findsOneWidget);
    expect(find.text('⚠ 3 low-confidence'), findsOneWidget);
    expect(find.text('+ Link scheme'), findsOneWidget);
    expect(find.text('Outdated syllabus'), findsOneWidget);
  });

  testWidgets('open a paper, add a suggested keyword and save', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('Open').at(4)); // 2019 Paper II
    await tester.pumpAndSettle();
    expect(find.textContaining('Q3 (b)'), findsOneWidget);
    expect(find.textContaining('OCR 94%'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'osmoreceptors'));
    await tester.pump();
    await tester.tap(find.text('Save & next question'));
    await tester.pumpAndSettle();

    final saved = (await repo.questions('p5')).first;
    expect(saved.keywords, contains('osmoreceptors'));
    expect(find.textContaining('Q3 (c)'), findsOneWidget); // moved on
  });

  testWidgets('uploads a paper, then follows its extraction until done', (
    tester,
  ) async {
    final repo = await _pump(tester, _Extracting());

    await tester.tap(find.text('Upload paper'));
    await tester.pumpAndSettle();

    expect(repo.uploads.single.$1, 'al-2024-p2.pdf');
    expect(
      find.text('al-2024-p2.pdf uploaded. Extracting questions...'),
      findsOneWidget,
    );
    expect(find.text('✓ 37 questions extracted'), findsNothing);

    // Two quiet reloads later the backend says it's done.
    await tester.pump(PastPapersController.pollEvery);
    await tester.pumpAndSettle();
    await tester.pump(PastPapersController.pollEvery);
    await tester.pumpAndSettle();

    expect(find.text('✓ 37 questions extracted'), findsWidgets);
    final readsWhenDone = repo.reads;
    await tester.pump(PastPapersController.pollEvery * 3);
    expect(repo.reads, readsWhenDone, reason: 'stops polling when done');
  });

  testWidgets('a refused upload shows the backend reason', (tester) async {
    await _pump(tester, _Extracting(failUpload: true));

    await tester.tap(find.text('Upload paper'));
    await tester.pumpAndSettle();

    expect(find.text('The 2024 Paper II is already uploaded'), findsOneWidget);
  });
}
