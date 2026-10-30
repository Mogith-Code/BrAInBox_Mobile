import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/app/dev/fake_backend.dart';
import 'package:brainbox_mobile/features/auth/application/auth_flow_controllers.dart';
import 'package:brainbox_mobile/features/auth/application/inbox_controller.dart';
import 'package:brainbox_mobile/features/auth/application/session_controller.dart';
import 'package:brainbox_mobile/features/auth/data/auth_repository.dart';
import 'package:brainbox_mobile/features/auth/domain/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = AppUser(id: 'u1', email: 'nethmi.p@gmail.com');
const _account = AuthAccount(uid: 'u1', email: 'nethmi.p@gmail.com');

ProviderContainer _withMock(AuthRepository repo) {
  SharedPreferences.setMockInitialValues({'welcome_seen': true});
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late _MockAuthRepository repo;

  setUp(() {
    repo = _MockAuthRepository();
    when(() => repo.accountChanges()).thenAnswer((_) => const Stream.empty());
  });

  group('Session', () {
    test('signed out -> no user', () async {
      when(() => repo.currentAccount).thenReturn(null);
      final c = _withMock(repo);
      final session = await c.read(sessionProvider.future);
      expect(session.signedIn, isFalse);
      expect(session.welcomeSeen, isTrue);
    });

    test('GET /auth/me 404 -> registers with the Firebase name', () async {
      when(() => repo.currentAccount).thenReturn(
        const AuthAccount(uid: 'u1', email: 'a@b.lk', displayName: 'Nethmi'),
      );
      when(() => repo.me()).thenThrow(
        const ApiException(
          code: 'USER_NOT_FOUND',
          message: '',
          statusCode: 404,
        ),
      );
      when(
        () => repo.register(fullName: 'Nethmi', consent: true),
      ).thenAnswer((_) async => _user);

      final c = _withMock(repo);
      final session = await c.read(sessionProvider.future);
      expect(session.signedIn, isTrue);
      verify(() => repo.register(fullName: 'Nethmi', consent: true)).called(1);
    });

    test('other API errors surface as an error state', () async {
      when(() => repo.currentAccount).thenReturn(_account);
      when(
        () => repo.me(),
      ).thenThrow(const ApiException(code: 'network', message: 'offline'));
      final c = _withMock(repo);
      await expectLater(
        c.read(sessionProvider.future),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('SignupController', () {
    test('creates the account, registers, sends the code', () async {
      var signedUp = false;
      when(
        () => repo.currentAccount,
      ).thenAnswer((_) => signedUp ? _account : null);
      when(
        () => repo.signUp(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => signedUp = true);
      when(
        () => repo.register(
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          consent: true,
        ),
      ).thenAnswer((_) async => _user);
      when(() => repo.me()).thenAnswer((_) async => _user);
      when(() => repo.sendEmailCode()).thenAnswer(
        (_) async => const CodeSent(resendIn: 42, devCode: '482715'),
      );

      final c = _withMock(repo);
      final ok = await c
          .read(signupControllerProvider.notifier)
          .submit(
            fullName: 'Nethmi Perera',
            email: 'nethmi.p@gmail.com',
            password: 'Mito2027',
            phone: '+94771234567',
          );

      expect(ok, isTrue);
      verify(
        () => repo.register(
          fullName: 'Nethmi Perera',
          phone: '+94771234567',
          consent: true,
        ),
      ).called(1);
      final pending = c.read(pendingCodeProvider(InboxMode.verifyEmail));
      expect(pending?.code.devCode, '482715');
    });

    test('a retry after a failed register does not sign up again', () async {
      when(() => repo.currentAccount).thenReturn(_account); // already exists
      when(
        () => repo.register(
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          consent: true,
        ),
      ).thenAnswer((_) async => _user);
      when(() => repo.me()).thenAnswer((_) async => _user);
      when(
        () => repo.sendEmailCode(),
      ).thenAnswer((_) async => const CodeSent());

      final c = _withMock(repo);
      await c
          .read(signupControllerProvider.notifier)
          .submit(fullName: 'N P', email: 'nethmi.p@gmail.com', password: 'x');

      verifyNever(
        () => repo.signUp(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('register failure is shown as an error', () async {
      when(() => repo.currentAccount).thenReturn(_account);
      when(
        () => repo.register(
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
          consent: true,
        ),
      ).thenThrow(const ApiException(code: 'network', message: 'offline'));

      final c = _withMock(repo);
      final ok = await c
          .read(signupControllerProvider.notifier)
          .submit(fullName: 'N P', email: 'nethmi.p@gmail.com', password: 'x');
      expect(ok, isFalse);
      expect(c.read(signupControllerProvider).error, isA<ApiException>());
    });
  });

  group('on the fake backend', () {
    test(
      'log in with the seeded account lands on a finished session',
      () async {
        final c = fakeContainer();
        addTearDown(c.dispose);
        final ok = await c
            .read(loginControllerProvider.notifier)
            .submit(email: 'nethmi.p@gmail.com', password: 'Mito2027');
        expect(ok, isTrue);
        final session = await c.read(sessionProvider.future);
        expect(session.diagnosticDone, isTrue);
      },
    );

    test('wrong password -> Firebase error', () async {
      final c = fakeContainer();
      addTearDown(c.dispose);
      // Keep the auto-dispose controller alive, like a screen would.
      final sub = c.listen(loginControllerProvider, (_, _) {});
      addTearDown(sub.close);
      await c
          .read(loginControllerProvider.notifier)
          .submit(email: 'nethmi.p@gmail.com', password: 'nope');
      expect(
        ErrorMessages.of(c.read(loginControllerProvider).error),
        'Email or password is incorrect.',
      );
    });

    test('inbox: wrong code, too many attempts, then the right code', () async {
      final backend = FakeBackend(latency: Duration.zero);
      final c = fakeContainer(backend: backend);
      addTearDown(c.dispose);
      await c
          .read(signupControllerProvider.notifier)
          .submit(
            fullName: 'Kavi Silva',
            email: 'kavi@gmail.com',
            password: 'Mito2027',
          );

      final inbox = inboxControllerProvider(InboxMode.verifyEmail);
      final sub = c.listen(inbox, (_, _) {});
      addTearDown(sub.close);

      expect(c.read(inbox).secondsLeft, FakeBackend.resendIn);
      expect(c.read(inbox).devCode, FakeBackend.devCode);

      expect(await c.read(inbox.notifier).verify('111111'), isFalse);
      expect(c.read(inbox).errorCode, 'CODE_INVALID');

      for (var i = 0; i < 4; i++) {
        await c.read(inbox.notifier).verify('111111');
      }
      expect(await c.read(inbox.notifier).verify('111111'), isFalse);
      expect(c.read(inbox).errorCode, 'TOO_MANY_ATTEMPTS');
      expect(c.read(inbox).needsNewCode, isTrue);
      expect(c.read(inbox).canResend, isTrue);
    });

    test('inbox: the right code verifies and the session moves on', () async {
      final c = fakeContainer();
      addTearDown(c.dispose);
      await c
          .read(signupControllerProvider.notifier)
          .submit(
            fullName: 'Kavi Silva',
            email: 'kavi@gmail.com',
            password: 'Mito2027',
          );
      expect((await c.read(sessionProvider.future)).emailVerified, isFalse);

      final inbox = inboxControllerProvider(InboxMode.verifyEmail);
      final sub = c.listen(inbox, (_, _) {});
      addTearDown(sub.close);
      expect(await c.read(inbox.notifier).verify(FakeBackend.devCode), isTrue);
      expect((await c.read(sessionProvider.future)).emailVerified, isTrue);
    });

    test('inbox: resend too soon shows the wait from retry_after', () async {
      final c = fakeContainer();
      addTearDown(c.dispose);
      await c
          .read(signupControllerProvider.notifier)
          .submit(
            fullName: 'Kavi Silva',
            email: 'kavi@gmail.com',
            password: 'Mito2027',
          );
      final inbox = inboxControllerProvider(InboxMode.verifyEmail);
      final sub = c.listen(inbox, (_, _) {});
      addTearDown(sub.close);

      await c.read(inbox.notifier).resend();
      expect(c.read(inbox).errorCode, 'RESEND_TOO_SOON');
      expect(c.read(inbox).secondsLeft, greaterThan(0));
    });

    test(
      'password reset: code -> token -> new password -> signed in',
      () async {
        final c = fakeContainer();
        addTearDown(c.dispose);
        expect(
          await c
              .read(forgotPasswordControllerProvider.notifier)
              .submit('nethmi.p@gmail.com'),
          isTrue,
        );
        final inbox = inboxControllerProvider(InboxMode.resetPassword);
        final sub = c.listen(inbox, (_, _) {});
        addTearDown(sub.close);
        expect(
          await c.read(inbox.notifier).verify(FakeBackend.devCode),
          isTrue,
        );
        expect(c.read(resetFlowProvider).resetToken, isNotNull);

        expect(
          await c
              .read(newPasswordControllerProvider.notifier)
              .submit('NewPass123'),
          isTrue,
        );
        expect(c.read(resetFlowProvider).resetToken, isNull); // forgotten
        expect((await c.read(sessionProvider.future)).signedIn, isTrue);
      },
    );

    test('new password without a token -> RESET_TOKEN_INVALID', () async {
      final c = fakeContainer();
      addTearDown(c.dispose);
      final sub = c.listen(newPasswordControllerProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(newPasswordControllerProvider.notifier).submit('NewPass123');
      final error = c.read(newPasswordControllerProvider).error;
      expect(error, isA<ApiException>());
      expect((error! as ApiException).code, 'RESET_TOKEN_INVALID');
    });
  });
}
