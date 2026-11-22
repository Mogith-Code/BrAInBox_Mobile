import 'package:brainbox_admin/features/users/data/users_repository.dart';
import 'package:brainbox_admin/features/users/domain/users_models.dart';
import 'package:brainbox_admin/features/users/presentation/users_screen.dart';
import 'package:brainbox_admin/widgets/save_file.dart';
import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// [count] students "Student 1".."Student N"; remembers every request, and
/// pages exactly like `GET /admin/users` (page + page_size, total).
class _PagedRepository implements UsersRepository {
  _PagedRepository(int count, {this.failExport = false})
    : rows = [
        for (var i = 1; i <= count; i++)
          AdminStudent(
            id: 'u$i',
            fullName: 'Student $i',
            email: 's$i@school.lk',
            status: i.isEven ? StudentStatus.active : StudentStatus.inactive,
          ),
      ];

  final List<AdminStudent> rows;
  final bool failExport;
  final requests = <Map<String, dynamic>>[];

  @override
  Future<StudentPage> students(
    StudentFilter filter, {
    int pageSize = StudentFilter.pageSize,
  }) async {
    requests.add(filter.toQuery(pageSize: pageSize));
    if (failExport && pageSize == StudentFilter.maxPageSize) {
      throw const ApiException(
        code: 'FORBIDDEN',
        message: 'You do not have permission to do this',
        statusCode: 403,
      );
    }
    final q = filter.search.trim().toLowerCase();
    final match = rows
        .where((s) => q.isEmpty || s.fullName.toLowerCase().contains(q))
        .toList();
    return StudentPage(
      items: match.skip((filter.page - 1) * pageSize).take(pageSize).toList(),
      total: match.length,
      activeTotal: match.where((s) => s.status == StudentStatus.active).length,
    );
  }

  @override
  Future<AdminStudent> setActive(String id, {required bool active}) =>
      throw UnimplementedError();
}

Future<List<(String, String)>> _pump(
  WidgetTester tester,
  UsersRepository repo,
) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final saved = <(String, String)>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        usersRepositoryProvider.overrideWithValue(repo),
        saveTextFileProvider.overrideWithValue((
          name,
          text, {
          mimeType = 'text/csv',
        }) async {
          saved.add((name, text));
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: UsersScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return saved;
}

void main() {
  testWidgets('pages through the students with the backend paging', (
    tester,
  ) async {
    final repo = _PagedRepository(60);
    await _pump(tester, repo);

    expect(find.text('Showing 1–25 of 60'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(repo.requests.last, {'page': 1, 'page_size': 25});

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    expect(repo.requests.last, {'page': 2, 'page_size': 25});
    expect(find.text('Showing 26–50 of 60'), findsOneWidget);
    expect(find.text('Student 26'), findsOneWidget);
  });

  testWidgets('typing searches after a pause and goes back to page 1', (
    tester,
  ) async {
    final repo = _PagedRepository(60);
    await _pump(tester, repo);
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Student 4');
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.requests.last['search'], isNull); // not yet
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repo.requests.last, {
      'search': 'Student 4',
      'page': 1,
      'page_size': 25,
    });
    // "Student 4" and "Student 40".."Student 49".
    expect(find.text('Showing 1–11 of 11'), findsOneWidget);
  });

  testWidgets('Export CSV saves every matching student, not just the page', (
    tester,
  ) async {
    final repo = _PagedRepository(230);
    final saved = await _pump(tester, repo);

    await tester.tap(find.text('Export CSV'));
    await tester.pumpAndSettle();

    final exportRequests = repo.requests
        .where((r) => r['page_size'] == StudentFilter.maxPageSize)
        .map((r) => r['page'])
        .toList();
    expect(exportRequests, [1, 2, 3]);
    expect(saved, hasLength(1));
    final (name, csv) = saved.single;
    expect(
      name,
      matches(RegExp(r'^brainbox-students-\d{4}-\d{2}-\d{2}\.csv$')),
    );
    final lines = csv.split('\r\n');
    expect(lines, hasLength(231)); // header + 230
    expect(lines[1], startsWith('Student 1,s1@school.lk,'));
    expect(find.text('Exported 230 students.'), findsOneWidget);
  });

  testWidgets('a failed export says why', (tester) async {
    final saved = await _pump(tester, _PagedRepository(30, failExport: true));

    await tester.tap(find.text('Export CSV'));
    await tester.pumpAndSettle();

    expect(saved, isEmpty);
    expect(
      find.text("Couldn't export. This account is not an admin."),
      findsOneWidget,
    );
  });

  test('CSV cells are quoted, and formulas are neutralised', () {
    final csv = studentsCsv([
      AdminStudent(
        id: '1',
        fullName: 'Perera, "Nethmi"',
        email: 'n@x.lk',
        school: '=HYPERLINK("http://evil")',
        district: 'Colombo',
        examYear: 2027,
        avgMastery: 74,
        lastActiveAt: DateTime.utc(2026, 11, 20, 8, 30),
      ),
      const AdminStudent(id: '2', fullName: 'New Student'),
    ]);
    final lines = csv.split('\r\n');
    expect(
      lines[0],
      'Name,Email,School,District,A/L year,Average mastery (%),Status,'
      'Last active',
    );
    expect(
      lines[1],
      '"Perera, ""Nethmi""",n@x.lk,"\'=HYPERLINK(""http://evil"")",Colombo,'
      '2027,74,Active,2026-11-20T08:30:00.000Z',
    );
    expect(lines[2], 'New Student,,,,,,Active,');
  });
}
