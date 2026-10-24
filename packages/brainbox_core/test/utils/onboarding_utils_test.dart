import 'package:brainbox_core/brainbox_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordStrength', () {
    test('empty and too-short passwords', () {
      expect(PasswordStrength.of(''), PasswordStrength.empty);
      expect(PasswordStrength.of('abc1'), PasswordStrength.weak);
      expect(
        PasswordStrength.of('abcdefgh'),
        PasswordStrength.weak,
      ); // no number
      expect(
        PasswordStrength.of('12345678'),
        PasswordStrength.weak,
      ); // no letter
    });

    test('the Figma example "Mito2027" is Good, asking for a symbol', () {
      expect(PasswordStrength.of('Mito2027'), PasswordStrength.good);
      expect(
        PasswordStrength.hintFor('Mito2027'),
        'Add a symbol to make it stronger',
      );
    });

    test('fair, good and strong', () {
      expect(PasswordStrength.of('mito2027'), PasswordStrength.fair);
      expect(PasswordStrength.of('mito2027!'), PasswordStrength.good);
      expect(PasswordStrength.of('Mito2027!'), PasswordStrength.strong);
      expect(PasswordStrength.hintFor('Mito2027!'), '');
    });
  });

  group('Sri Lankan mobile', () {
    test('accepts the usual ways of typing it and normalises to +94', () {
      for (final input in [
        '77 123 4567',
        '0771234567',
        '771234567',
        '+94 77 123 4567',
        '94771234567',
      ]) {
        expect(Validators.sriLankanMobile(input), isNull, reason: input);
        expect(
          Validators.normalizeSriLankanMobile(input),
          '+94771234567',
          reason: input,
        );
      }
    });

    test('is optional', () {
      expect(Validators.sriLankanMobile(''), isNull);
      expect(Validators.sriLankanMobile(null), isNull);
    });

    test('rejects landlines, short and long numbers', () {
      for (final input in ['011 234 5678', '77 123 456', '77 123 45678']) {
        expect(Validators.sriLankanMobile(input), isNotNull, reason: input);
      }
    });
  });

  group('Validators', () {
    test('full name', () {
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName('N'), isNotNull);
      expect(Validators.fullName('Nethmi Perera'), isNull);
    });

    test('otp code', () {
      expect(Validators.otpCode('48271'), isNotNull);
      expect(Validators.otpCode('48271a'), isNotNull);
      expect(Validators.otpCode('482715'), isNull);
    });
  });

  group('Formatters', () {
    test('weekdayDayMonth matches the Home design', () {
      expect(
        Formatters.weekdayDayMonth(DateTime(2025, 10, 7)),
        'Tuesday, 7 Oct',
      );
    });

    test('countdown', () {
      expect(Formatters.countdown(42), '0:42');
      expect(Formatters.countdown(75), '1:15');
      expect(Formatters.countdown(-3), '0:00');
    });

    test('initials', () {
      expect(Formatters.initials('Nethmi Perera'), 'NP');
      expect(Formatters.initials('nethmi'), 'N');
      expect(Formatters.initials('  '), '');
    });
  });

  group('ErrorMessages', () {
    test('known backend codes get our own text', () {
      const error = ApiException(code: 'CODE_EXPIRED', message: 'raw');
      expect(
        ErrorMessages.of(error),
        'That code has expired. Ask for a new one.',
      );
    });

    test('RESEND_TOO_SOON includes retry_after', () {
      const error = ApiException(
        code: 'RESEND_TOO_SOON',
        message: 'raw',
        retryAfter: 30,
      );
      expect(ErrorMessages.of(error), contains('30 seconds'));
    });

    test('unknown codes fall back to the backend message', () {
      const error = ApiException(code: 'SOMETHING_NEW', message: 'From server');
      expect(ErrorMessages.of(error), 'From server');
    });

    test('anything else is generic', () {
      expect(ErrorMessages.of(Exception('x')), ErrorMessages.generic);
    });
  });

  group('ApiException.fromDioException', () {
    DioException errorWith(Map<String, dynamic> body, {Headers? headers}) {
      final request = RequestOptions(path: '/x');
      return DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 429,
          data: body,
          headers: headers,
        ),
      );
    }

    test('reads retry_after from the error body', () {
      final e = ApiException.fromDioException(
        errorWith({
          'error': {
            'code': 'RESEND_TOO_SOON',
            'message': 'm',
            'retry_after': 25,
          },
        }),
      );
      expect(e.code, 'RESEND_TOO_SOON');
      expect(e.retryAfter, 25);
      expect(e.statusCode, 429);
    });

    test('reads retry_after from the Retry-After header', () {
      final e = ApiException.fromDioException(
        errorWith(
          {
            'error': {'code': 'RESEND_TOO_SOON', 'message': 'm'},
          },
          headers: Headers.fromMap({
            'retry-after': ['12'],
          }),
        ),
      );
      expect(e.retryAfter, 12);
    });
  });

  test('AppUser reads the backend UserOut shape', () {
    final user = AppUser.fromJson({
      'id': 'u1',
      'email': 'nethmi.p@gmail.com',
      'full_name': 'Nethmi Perera',
      'phone': '+94771234567',
      'role': 'student',
      'email_verified': true,
      'onboarding': {
        'profile_completed': true,
        'diagnostic_completed': false,
        'diagnostic_skipped': true,
      },
    });
    expect(user.firstName, 'Nethmi');
    expect(user.onboarding.profileCompleted, isTrue);
    expect(user.onboarding.diagnosticSkipped, isTrue);
  });
}
