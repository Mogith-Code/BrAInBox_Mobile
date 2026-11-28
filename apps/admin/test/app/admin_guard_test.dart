import 'package:brainbox_admin/app/admin_shell.dart';
import 'package:brainbox_admin/app/router.dart';
import 'package:brainbox_admin/features/auth/application/admin_session.dart';
import 'package:brainbox_admin/features/auth/data/auth_repository.dart';
import 'package:brainbox_admin/features/users/data/users_repository.dart';
import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository {}

/// The session the test is in; tests switch it to sign in / out.
class _Session extends Notifier<AdminSession> {
  _Session(this.initial);

  final AdminSession initial;

  @override
  AdminSession build() => initial;

  void set(AdminSession s) => state = s;
}

const _admin = AdminSession(
  AdminSessionStatus.admin,
  user: AppUser(id: 'a1', email: 'admin@brainbox.lk', role: 'admin'),
);
const _student = AdminSession(
  AdminSessionStatus.notAdmin,
  user: AppUser(id: 's1', email: 'nethmi@gmail.com'),
);

void main() {
  group('adminRedirect', () {
    String? go(AdminSession s, String location) =>
        adminRedirect(s, Uri.parse(location));

    test('signed out: every page goes to login, remembering the page', () {
      const out = AdminSession.signedOut();
      expect(go(out, '/users?page=2'), '/login?from=%2Fusers%3Fpage%3D2');
      expect(go(out, '/dashboard'), '/login');
      expect(go(out, '/login'), isNull);
      expect(go(out, '/not-admin'), '/login');
    });

    test('checking or failed: the session page, never a data page', () {
      expect(
        go(const AdminSession.checking(), '/users'),
        '/session?from=%2Fusers',
      );
      expect(
        go(const AdminSession(AdminSessionStatus.failed), '/syllabus'),
        '/session?from=%2Fsyllabus',
      );
      expect(go(const AdminSession.checking(), '/session'), isNull);
    });

    test('not an admin: always the not-admin page', () {
      expect(go(_student, '/users'), '/not-admin');
      expect(go(_student, '/login'), '/not-admin');
      expect(go(_student, '/not-admin'), isNull);
    });

    test('admin: gate pages send to `from` (if safe) or the dashboard', () {
      expect(go(_admin, '/login'), '/dashboard');
      expect(go(_admin, '/login?from=%2Fusers%3Fpage%3D2'), '/users?page=2');
      expect(go(_admin, '/session?from=%2Fmoderation'), '/moderation');
      expect(go(_admin, '/not-admin'), '/dashboard');
      expect(go(_admin, '/login?from=https://evil.example'), '/dashboard');
      expect(go(_admin, '/login?from=//evil.example'), '/dashboard');
      expect(go(_admin, '/login?from=%2Flogin'), '/dashboard');
      expect(go(_admin, '/users'), isNull);
    });
  });

  group('router guard', () {
    late _MockAuth auth;
    late ProviderContainer container;
    late GoRouter router;

    _Session session() => container.read(_sessionProvider.notifier);

    Future<void> pumpRouter(WidgetTester tester, AdminSession start) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      auth = _MockAuth();
      when(() => auth.signOut()).thenAnswer((_) async {
        session().set(const AdminSession.signedOut());
      });
      _sessionProvider = NotifierProvider<_Session, AdminSession>(
        () => _Session(start),
      );
      container = ProviderContainer(
        overrides: [
          adminSessionProvider.overrideWith(
            (ref) => ref.watch(_sessionProvider),
          ),
          authRepositoryProvider.overrideWithValue(auth),
          usersRepositoryProvider.overrideWithValue(FakeUsersRepository()),
        ],
      );
      addTearDown(container.dispose);
      // Listen like the app's `ref.watch(routerProvider)` does: Riverpod 3
      // pauses a provider nobody listens to, and its guard with it.
      container.listen(routerProvider, (_, _) {});
      router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('not signed in: every sidebar page shows the login page', (
      tester,
    ) async {
      await pumpRouter(tester, const AdminSession.signedOut());

      for (final item in AdminShell.navItems) {
        router.go(item.path);
        await tester.pumpAndSettle();
        expect(
          find.text('Sign in to console'),
          findsOneWidget,
          reason: item.path,
        );
        expect(find.byType(AdminShell), findsNothing, reason: item.path);
        expect(find.byType(ErrorBanner), findsNothing, reason: item.path);
      }
    });

    testWidgets('signing in opens the page that was asked for', (tester) async {
      await pumpRouter(tester, const AdminSession.signedOut());
      router.go('/users');
      await tester.pumpAndSettle();
      expect(find.text('Sign in to console'), findsOneWidget);

      session().set(const AdminSession.checking());
      // The spinner never settles, so pump a few frames instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Checking your account…'), findsOneWidget);
      expect(find.byType(AdminShell), findsNothing);

      session().set(_admin);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/users');
      expect(find.text('Students'), findsOneWidget);
    });

    testWidgets('a non-admin sees the not-admin page and can log out', (
      tester,
    ) async {
      await pumpRouter(tester, _student);
      router.go('/users');
      await tester.pumpAndSettle();

      expect(find.text('This account is not an admin.'), findsOneWidget);
      expect(find.textContaining('nethmi@gmail.com'), findsOneWidget);
      expect(find.byType(AdminShell), findsNothing);

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      verify(() => auth.signOut()).called(1);
      expect(find.text('Sign in to console'), findsOneWidget);
    });

    testWidgets('a failed account check offers Retry and Log out', (
      tester,
    ) async {
      await pumpRouter(
        tester,
        const AdminSession(
          AdminSessionStatus.failed,
          error: ApiException(
            code: 'USER_DISABLED',
            message: 'This account is disabled',
            statusCode: 403,
          ),
        ),
      );

      expect(find.text("Couldn't check your account"), findsOneWidget);
      expect(find.text('This account is disabled.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
    });
  });
}

late NotifierProvider<_Session, AdminSession> _sessionProvider;
