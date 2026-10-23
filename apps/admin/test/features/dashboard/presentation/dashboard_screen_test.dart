import 'package:brainbox_admin/features/dashboard/data/dashboard_repository.dart';
import 'package:brainbox_admin/features/dashboard/domain/dashboard_models.dart';
import 'package:brainbox_admin/features/dashboard/presentation/dashboard_screen.dart';
import 'package:brainbox_admin/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:brainbox_admin/features/dashboard/presentation/widgets/kpi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements DashboardRepository {}

void main() {
  late _MockRepository repository;

  Future<void> pumpDashboard(
    WidgetTester tester,
    DashboardSummary summary, {
    Size size = const Size(1280, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Fake the data layer so the test never touches the network.
    repository = _MockRepository();
    when(() => repository.fetchSummary()).thenAnswer((_) async => summary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows KPIs, reports and missed topics from the repository', (
    tester,
  ) async {
    await pumpDashboard(tester, DashboardRepository.sampleSummary);

    verify(() => repository.fetchSummary()).called(1);
    expect(find.byType(KpiCard), findsNWidgets(4));
    expect(find.text('Active students'), findsOneWidget);
    expect(find.text('2,418'), findsOneWidget);
    expect(find.text('Wrong answer key'), findsOneWidget);
    expect(find.text('Dihybrid crosses & linkage'), findsOneWidget);
    expect(find.text('64%'), findsOneWidget);
    expect(find.text('Based on 41,208 attempts'), findsOneWidget);
    // Sample data is labelled as such on screen.
    expect(
      find.text('Placeholder data - API not connected yet.'),
      findsOneWidget,
    );
  });

  testWidgets('empty data shows empty states, not errors', (tester) async {
    await pumpDashboard(tester, const DashboardSummary(title: 'Test'));

    expect(find.byType(KpiCard), findsNothing);
    expect(find.text('No activity yet.'), findsOneWidget);
    expect(find.text('No reports right now.'), findsOneWidget);
    expect(find.text('No attempts this week yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow width lays out without overflow', (tester) async {
    await pumpDashboard(
      tester,
      DashboardRepository.sampleSummary,
      size: const Size(420, 2400),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(KpiCard), findsNWidgets(4));
  });

  testWidgets('unconnected actions say so instead of failing', (tester) async {
    await pumpDashboard(tester, DashboardRepository.sampleSummary);

    await tester.tap(find.text('Export'));
    await tester.pump();

    expect(find.text('Export is not connected yet.'), findsOneWidget);
  });

  group('DashboardHeader', () {
    test('formats the long date', () {
      expect(
        DashboardHeader.longDate(DateTime(2026, 10, 7)),
        'Wednesday, 7 October 2026',
      );
    });

    test('greets by time of day', () {
      expect(DashboardHeader.greeting(DateTime(2026, 1, 1, 9)), 'Good morning');
      expect(
        DashboardHeader.greeting(DateTime(2026, 1, 1, 14)),
        'Good afternoon',
      );
      expect(
        DashboardHeader.greeting(DateTime(2026, 1, 1, 20)),
        'Good evening',
      );
    });
  });
}
