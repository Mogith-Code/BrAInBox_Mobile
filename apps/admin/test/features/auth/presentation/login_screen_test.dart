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

void main() {
  late _MockRepository repository;

  Future<void> pumpLogin(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Fake the data layer so the test never touches the network.
    repository = _MockRepository();
    when(
      () => repository.fetchSummary(),
    ).thenAnswer((_) async => const AuthSummary(title: 'Test'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wide: brand panel next to the sign-in form', (tester) async {
    await pumpLogin(tester, const Size(1400, 900));

    expect(find.byType(LoginBrandPanel), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign in to console'), findsOneWidget);
    verify(() => repository.fetchSummary()).called(1);
  });

  testWidgets('narrow: form only, with the logo above it', (tester) async {
    await pumpLogin(tester, const Size(600, 900));

    expect(find.byType(LoginBrandPanel), findsNothing);
    expect(find.byType(AdminLogo), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('empty form shows validation errors', (tester) async {
    await pumpLogin(tester, const Size(1400, 900));

    await tester.tap(find.text('Sign in to console'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('valid form says sign-in is not connected yet', (tester) async {
    await pumpLogin(tester, const Size(1400, 900));

    await tester.enterText(find.byType(TextFormField).first, 'a@b.lk');
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.tap(find.text('Sign in to console'));
    await tester.pump();

    expect(find.text('Sign-in is not connected yet.'), findsOneWidget);
  });
}
