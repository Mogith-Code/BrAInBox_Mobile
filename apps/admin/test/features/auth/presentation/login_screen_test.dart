import 'package:brainbox_admin/features/auth/data/auth_repository.dart';
import 'package:brainbox_admin/features/auth/domain/auth_models.dart';
import 'package:brainbox_admin/features/auth/presentation/login_screen.dart';
import 'package:brainbox_admin/features/auth/presentation/widgets/login_brand_panel.dart';
import 'package:brainbox_admin/widgets/admin_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

const _admin = AppUser(id: 'a1', email: 'tharushi@brainbox.lk', role: 'admin');

void main() {
  late _MockRepository repository;

  Future<void> pumpLogin(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Fake the data layer so the test never touches Firebase.
    repository = _MockRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, 'a@b.lk');
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.tap(find.text('Sign in to console'));
    await tester.pumpAndSettle();
  }

  void answer(Future<AppUser> Function() result) => when(
    () => repository.signIn(
      email: any(named: 'email'),
      password: any(named: 'password'),
      keepSignedIn: any(named: 'keepSignedIn'),
    ),
  ).thenAnswer((_) => result());

  testWidgets('wide: brand panel next to the sign-in form', (tester) async {
    await pumpLogin(tester, const Size(1400, 900));

    expect(find.byType(LoginBrandPanel), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign in to console'), findsOneWidget);
  });

  testWidgets('narrow: form only, with the logo above it', (tester) async {
    await pumpLogin(tester, const Size(600, 900));

    expect(find.byType(LoginBrandPanel), findsNothing);
    expect(find.byType(AdminLogo), findsOneWidget);
  });

  testWidgets('empty form shows validation errors', (tester) async {
    await pumpLogin(tester, const Size(1400, 900));

    await tester.tap(find.text('Sign in to console'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    verifyNever(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
        keepSignedIn: any(named: 'keepSignedIn'),
      ),
    );
  });

  testWidgets('signs in with the typed email, password and checkbox', (
    tester,
  ) async {
    await pumpLogin(tester, const Size(1400, 900));
    answer(() async => _admin);

    await tester.tap(find.text('Keep me signed in')); // turns it off
    await fillAndSubmit(tester);

    verify(
      () => repository.signIn(
        email: 'a@b.lk',
        password: 'secret',
        keepSignedIn: false,
      ),
    ).called(1);
    expect(find.text(NotAdminException.message), findsNothing);
  });

  testWidgets('a student account is refused', (tester) async {
    await pumpLogin(tester, const Size(1400, 900));
    answer(() async => throw const NotAdminException());

    await fillAndSubmit(tester);

    expect(find.text('This account is not an admin.'), findsOneWidget);
  });

  testWidgets('Forgot password explains the reset through the app', (
    tester,
  ) async {
    await pumpLogin(tester, const Size(1400, 900));

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
  });
}
