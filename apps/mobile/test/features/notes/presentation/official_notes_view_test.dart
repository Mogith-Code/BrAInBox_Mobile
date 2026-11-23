import 'dart:typed_data';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/routes.dart';
import 'package:brainbox_mobile/features/syllabus/data/learn_repository.dart';
import 'package:brainbox_mobile/features/syllabus/data/mock_learn_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../syllabus/learn_test_app.dart';

/// The mock, plus a list of requested pages and an optional failure.
class _PagesRepo extends MockLearnRepository {
  _PagesRepo() : super(latency: Duration.zero);

  final requested = <String>[];
  bool failPages = false;

  @override
  Future<Uint8List> fetchOfficialPage(String documentId, int page) async {
    requested.add('$documentId/$page');
    if (failPages) {
      throw const ApiException(code: 'x', message: 'Page failed');
    }
    return super.fetchOfficialPage(documentId, page);
  }
}

void main() {
  Future<void> open(WidgetTester tester, _PagesRepo repo, String topic) =>
      pumpLearnApp(
        tester,
        repository: repo,
        initialLocation: AppRoutes.topicPath(topic),
      );

  testWidgets('opens on Government notes and loads only visible pages', (
    tester,
  ) async {
    final repo = _PagesRepo();
    await open(tester, repo, 't-scope');

    expect(find.text('Page 1 of 5'), findsOneWidget);
    expect(find.text('Showing this unit from the start.'), findsNothing);
    expect(repo.requested, isNot(contains('book-1/5')));
    // The visible page really finished loading.
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('reaching the last page sends a completed read', (tester) async {
    final repo = _PagesRepo();
    await open(tester, repo, 't-scope');
    bool completed() =>
        repo.progressLog.any((e) => e.$2 == ProgressEvent.read && e.$3);
    expect(completed(), isFalse);

    await tester.fling(find.byType(ListView), const Offset(0, -6000), 6000);
    await tester.pumpAndSettle();

    expect(find.text('Page 5 of 5'), findsOneWidget);
    expect(completed(), isTrue);
  });

  testWidgets('a unit with two books can switch book', (tester) async {
    final repo = _PagesRepo();
    await open(tester, repo, 't-digestion');

    expect(find.text('Showing this unit from the start.'), findsOneWidget);
    expect(find.text('Page 1 of 3'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<OfficialBook>));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Unit 5: Animal Form And Function (Part 2)').last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(repo.requested, contains('book-5b/1'));
  });

  testWidgets('a failed page shows Retry, and Retry loads it', (tester) async {
    final repo = _PagesRepo()..failPages = true;
    await open(tester, repo, 't-scope');
    // The page request starts in the last frame: let its error arrive.
    await tester.pump();
    expect(find.text('Retry'), findsWidgets);

    repo.failPages = false;
    await tester.tap(find.text('Retry').first);
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('no book: shows the message and AI notes stay reachable', (
    tester,
  ) async {
    final repo = _PagesRepo();
    await open(tester, repo, 't-mendelian');

    expect(
      find.text("Government notes aren't available for this topic yet"),
      findsOneWidget,
    );
    await tester.tap(find.text('AI notes'));
    await tester.pumpAndSettle();
    expect(find.text('Genotype and phenotype'), findsOneWidget);
  });

  test(
    'page bytes go through the shared Dio with ResponseType.bytes',
    () async {
      late RequestOptions seen;
      final dio = Dio(BaseOptions(baseUrl: 'http://test'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              seen = options;
              handler.resolve(
                Response<List<int>>(
                  requestOptions: options,
                  data: const [1, 2, 3],
                  statusCode: 200,
                ),
              );
            },
          ),
        );
      final api = ApiClient(
        dio: dio,
        getIdToken: ({forceRefresh = false}) async => 'tok',
      );

      final bytes = await api.getBytes('/learn/official-notes/d1/pages/2');

      expect(bytes, [1, 2, 3]);
      expect(seen.responseType, ResponseType.bytes);
      expect(seen.path, '/learn/official-notes/d1/pages/2');
    },
  );
}
