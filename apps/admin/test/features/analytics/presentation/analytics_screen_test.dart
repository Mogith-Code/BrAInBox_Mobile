import 'package:brainbox_admin/features/analytics/data/analytics_repository.dart';
import 'package:brainbox_admin/features/analytics/domain/analytics_models.dart';
import 'package:brainbox_admin/features/analytics/presentation/analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AnalyticsRepository {}

void main() {
  testWidgets('AnalyticsScreen shows data from the repository', (tester) async {
    // Fake the data layer so the test never touches the network.
    final repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const AnalyticsSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: AnalyticsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coming soon'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });
}
