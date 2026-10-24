import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiClient {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

const _userJson = {
  'id': 'u1',
  'email': 'nethmi.p@gmail.com',
  'full_name': 'Nethmi Perera',
  'phone': '+94771234567',
  'role': 'student',
  'email_verified': false,
  'onboarding': {
    'profile_completed': false,
    'diagnostic_completed': false,
    'diagnostic_skipped': false,
  },
};

void main() {
  late _MockApi api;
  late _MockFirebaseAuth auth;
  late ApiAuthRepository repo;

  setUp(() {
    api = _MockApi();
    auth = _MockFirebaseAuth();
    repo = ApiAuthRepository(api, firebaseAuth: auth);
  });

  test('register sends snake_case JSON and parses UserOut', () async {
    when(
      () => api.post<Map<String, dynamic>>(
        '/auth/register',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => Map<String, dynamic>.of(_userJson));

    final user = await repo.register(
      fullName: 'Nethmi Perera',
      phone: '+94771234567',
      consent: true,
    );

    expect(user.fullName, 'Nethmi Perera');
    final sent =
        verify(
              () => api.post<Map<String, dynamic>>(
                '/auth/register',
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map;
    expect(sent, {
      'full_name': 'Nethmi Perera',
      'phone': '+94771234567',
      'consent': true,
    });
  });

  test('register leaves out a missing phone', () async {
    when(
      () => api.post<Map<String, dynamic>>(
        '/auth/register',
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => Map<String, dynamic>.of(_userJson));
    await repo.register(fullName: 'N', consent: true);
    final sent =
        verify(
              () => api.post<Map<String, dynamic>>(
                '/auth/register',
                data: captureAny(named: 'data'),
              ),
            ).captured.single
            as Map;
    expect(sent.containsKey('phone'), isFalse);
  });

  test('a bare 404 from /auth/me becomes USER_NOT_FOUND', () async {
    when(() => api.get<Map<String, dynamic>>('/auth/me')).thenThrow(
      const ApiException(
        code: 'http_404',
        message: 'Not Found',
        statusCode: 404,
      ),
    );
    await expectLater(
      repo.me(),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'USER_NOT_FOUND'),
      ),
    );
  });

  test('sendEmailCode parses resend_in and dev_code', () async {
    when(
      () => api.post<Map<String, dynamic>>('/auth/email-code/send'),
    ).thenAnswer(
      (_) async => {
        'sent': true,
        'resend_in': 42,
        'expires_in': 600,
        'dev_code': '482715',
      },
    );
    final code = await repo.sendEmailCode();
    expect(code.resendIn, 42);
    expect(code.devCode, '482715');
  });

  test('verifyResetCode returns the reset token', () async {
    when(
      () => api.post<Map<String, dynamic>>(
        '/auth/password-reset/verify',
        data: {'email': 'a@b.lk', 'code': '123456'},
      ),
    ).thenAnswer((_) async => {'reset_token': 'tok', 'expires_in': 600});
    final token = await repo.verifyResetCode(email: 'a@b.lk', code: '123456');
    expect(token.resetToken, 'tok');
  });

  test('signUp creates the Firebase user and sets the display name', () async {
    final credential = _MockCredential();
    final user = _MockUser();
    when(() => credential.user).thenReturn(user);
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
    when(
      () => auth.createUserWithEmailAndPassword(
        email: 'a@b.lk',
        password: 'Mito2027',
      ),
    ).thenAnswer((_) async => credential);

    await repo.signUp(
      fullName: 'Nethmi',
      email: 'a@b.lk',
      password: 'Mito2027',
    );

    verify(() => user.updateDisplayName('Nethmi')).called(1);
  });

  test('currentAccount maps the Firebase user', () {
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('a@b.lk');
    when(() => user.displayName).thenReturn('Nethmi');
    when(() => user.emailVerified).thenReturn(true);
    when(() => auth.currentUser).thenReturn(user);

    final account = repo.currentAccount!;
    expect(account.uid, 'u1');
    expect(account.emailVerified, isTrue);
  });
}
