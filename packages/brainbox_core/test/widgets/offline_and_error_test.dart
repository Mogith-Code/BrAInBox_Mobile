import 'package:brainbox_core/brainbox_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Handler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {}
}

void main() {
  group('NetworkStatusInterceptor', () {
    final reports = <bool>[];
    final interceptor = NetworkStatusInterceptor(reports.add);
    final request = RequestOptions(path: '/x');

    setUp(reports.clear);

    test('cannot connect = offline', () {
      interceptor.onError(
        DioException(
          requestOptions: request,
          type: DioExceptionType.connectionError,
        ),
        _Handler(),
      );
      expect(reports, [false]);
    });

    test('any answer from the server = online, even an error', () {
      interceptor.onError(
        DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: request, statusCode: 500),
        ),
        _Handler(),
      );
      expect(reports, [true]);
    });
  });

  testWidgets('the offline banner shows only while offline', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var retried = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              onRetry: () async => retried++,
              child: const Text('page'),
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining("You're offline"), findsNothing);

    container.read(networkStatusProvider.notifier).report(online: false);
    await tester.pumpAndSettle();
    expect(
      find.text("You're offline. Saved notes still work."),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    expect(retried, 1);

    container.read(networkStatusProvider.notifier).report(online: true);
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsNothing);
  });

  testWidgets('AiErrorState shows the code and both actions', (tester) async {
    var retried = false;
    var reported = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiErrorState(
            title: "We couldn't generate your notes",
            message: 'Nothing was lost.',
            errorCode: 'AI-504',
            onRetry: () => retried = true,
            onReport: () => reported = true,
          ),
        ),
      ),
    );

    expect(find.text('Error code: AI-504'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.tap(find.text('Report a problem'));
    expect(retried, isTrue);
    expect(reported, isTrue);
  });
}
