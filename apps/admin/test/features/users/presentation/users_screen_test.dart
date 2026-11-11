import 'package:brainbox_admin/features/users/data/users_repository.dart';
import 'package:brainbox_admin/features/users/domain/users_models.dart';
import 'package:brainbox_admin/features/users/presentation/users_screen.dart';
import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingRepository extends FakeUsersRepository {
  @override
  Future<AdminStudent> setActive(String id, {required bool active}) =>
      throw const ApiException(code: 'network', message: 'offline');
}

Future<void> _pump(WidgetTester tester, UsersRepository repo) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [usersRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: UsersScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('the filter becomes the query string', () {
    expect(const StudentFilter().toQuery(), isEmpty);
    expect(
      const StudentFilter(
        search: ' nethmi ',
        examYear: 2027,
        status: StudentStatus.suspended,
      ).toQuery(),
      {'search': 'nethmi', 'exam_year': 2027, 'status': 'suspended'},
    );
  });

  testWidgets('lists students with counts, mastery and status', (tester) async {
    await _pump(tester, FakeUsersRepository());

    expect(find.text('Students'), findsOneWidget);
    expect(find.text('2,418 active · 3,105 total'), findsOneWidget);
    expect(find.text('Nethmi Perera'), findsOneWidget);
    expect(find.text('74%'), findsOneWidget);
    expect(find.text('Suspended'), findsOneWidget); // Ruwan
    expect(find.text('Reinstate'), findsOneWidget);
  });

  testWidgets('filters by status', (tester) async {
    await _pump(tester, FakeUsersRepository());

    await tester.tap(find.text('Status: '));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suspended').last);
    await tester.pumpAndSettle();

    expect(find.text('Ruwan Jayasinghe'), findsOneWidget);
    expect(find.text('Nethmi Perera'), findsNothing);
  });

  testWidgets('suspend asks first, then updates the row', (tester) async {
    await _pump(tester, FakeUsersRepository());

    await tester.tap(find.text('Suspend').first);
    await tester.pumpAndSettle();
    expect(find.text('Suspend Nethmi Perera?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
    await tester.pumpAndSettle();

    expect(find.text('Reinstate'), findsNWidgets(2)); // Ruwan + Nethmi
  });

  testWidgets('a failed suspend rolls back and says so', (tester) async {
    await _pump(tester, _FailingRepository());

    await tester.tap(find.text('Suspend').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
    await tester.pumpAndSettle();

    expect(find.text('Reinstate'), findsOneWidget); // only Ruwan
    expect(
      find.textContaining("Couldn't update Nethmi Perera"),
      findsOneWidget,
    );
  });

  testWidgets('a missing backend endpoint shows Not connected yet', (
    tester,
  ) async {
    await _pump(tester, _MissingEndpoint());
    expect(find.text('Not connected yet'), findsOneWidget);
  });
}

class _MissingEndpoint extends FakeUsersRepository {
  @override
  Future<StudentPage> students(StudentFilter filter) =>
      throw const ApiException(
        code: 'http_404',
        message: 'Not Found',
        statusCode: 404,
      );
}
