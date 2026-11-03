import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/auth/application/auth_flow_controllers.dart';
import 'package:brainbox_mobile/features/auth/application/session_controller.dart';
import 'package:brainbox_mobile/features/auth/data/auth_repository.dart';
import 'package:brainbox_mobile/features/auth/domain/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _account = AuthAccount(uid: 'u1', email: 'kavi@gmail.com');
const _disabled = ApiException(
  code: 'USER_DISABLED',
  message: 'This account is disabled',
  statusCode: 403,
);

ProviderContainer _container(AuthRepository repo) {
  SharedPreferences.setMockInitialValues({'welcome_seen': true});
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  late _MockAuthRepository repo;

  setUp(() {
    repo = _MockAuthRepository();
    when(() => repo.accountChanges()).thenAnswer((_) => const Stream.empty());
    when(() => repo.signOut()).thenAnswer((_) async {});
  });

  test('USER_NOT_REGISTERED registers, using the email when there is no '
      'name', () async {
    when(() => repo.currentAccount).thenReturn(_account);
    when(
      () => repo.me(),
    ).thenThrow(const ApiException(code: 'USER_NOT_REGISTERED', message: 'x'));
    when(
      () => repo.register(fullName: 'kavi', consent: true),
    ).thenAnswer((_) async => const AppUser(id: 'u1', email: 'kavi@gmail.com'));

    final session = await _container(repo).read(sessionProvider.future);

    expect(session.signedIn, isTrue);
    verify(() => repo.register(fullName: 'kavi', consent: true)).called(1);
  });

  test('USER_DISABLED signs out and keeps the reason', () async {
    when(() => repo.currentAccount).thenReturn(_account);
    when(() => repo.me()).thenThrow(_disabled);

    final session = await _container(repo).read(sessionProvider.future);

    expect(session.signedIn, isFalse);
    expect(session.signedOutReason?.code, 'USER_DISABLED');
    verify(() => repo.signOut()).called(1);
  });

  test('log in to a disabled account shows the error', () async {
    var signedIn = false;
    when(
      () => repo.currentAccount,
    ).thenAnswer((_) => signedIn ? _account : null);
    when(
      () => repo.signIn(email: 'kavi@gmail.com', password: 'Mito2027'),
    ).thenAnswer((_) async => signedIn = true);
    when(() => repo.me()).thenThrow(_disabled);
    when(() => repo.signOut()).thenAnswer((_) async => signedIn = false);

    final c = _container(repo);
    final sub = c.listen(loginControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(sessionProvider.future);

    final ok = await c
        .read(loginControllerProvider.notifier)
        .submit(email: 'kavi@gmail.com', password: 'Mito2027');

    expect(ok, isFalse);
    expect(
      ErrorMessages.of(c.read(loginControllerProvider).error),
      'This account is disabled. Contact your teacher.',
    );
    expect(signedIn, isFalse);
  });
}
