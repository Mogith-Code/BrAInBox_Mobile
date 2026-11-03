import 'package:brainbox_core/brainbox_core.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 401 response with the backend's error body.
Response<dynamic> _response401(String? code) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/auth/me'),
  statusCode: 401,
  data: code == null
      ? null
      : {
          'error': {'code': code, 'message': 'x'},
        },
);

void main() {
  group('AuthInterceptor.isExpiredToken', () {
    test('refreshes only for INVALID_TOKEN', () {
      expect(
        AuthInterceptor.isExpiredToken(_response401('INVALID_TOKEN')),
        isTrue,
      );
      expect(
        AuthInterceptor.isExpiredToken(_response401('USER_NOT_REGISTERED')),
        isFalse,
      );
    });

    test('a 401 without our error body counts as expired', () {
      expect(AuthInterceptor.isExpiredToken(_response401(null)), isTrue);
    });
  });

  group('ApiException.fieldErrors', () {
    test('maps known codes to a field', () {
      const e = ApiException(code: 'INVALID_PHONE', message: 'Bad phone');
      expect(e.fieldErrors, {'phone': 'Bad phone'});
    });

    test('reads VALIDATION_ERROR details', () {
      const e = ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Request data is invalid',
        details: {
          'details': [
            {'field': 'body.full_name', 'message': 'Too short'},
          ],
        },
      );
      expect(e.fieldErrors, {'full_name': 'Too short'});
    });

    test('other errors belong to no field', () {
      const e = ApiException(code: 'network', message: 'offline');
      expect(e.fieldErrors, isEmpty);
    });
  });

  group('ErrorMessages', () {
    test('CODE_INVALID says how many tries are left', () {
      const e = ApiException(
        code: 'CODE_INVALID',
        message: 'x',
        details: {'attempts_left': 2},
      );
      expect(ErrorMessages.of(e), "That code isn't right. 2 tries left.");
    });

    test('forField uses our text for the field', () {
      const e = ApiException(code: 'INVALID_PHONE', message: 'raw');
      expect(
        ErrorMessages.forField(e, 'phone'),
        'Enter a Sri Lankan mobile number, e.g. 077 123 4567.',
      );
      expect(ErrorMessages.forField(e, 'email'), isNull);
      expect(ErrorMessages.isOnlyFieldError(e), isTrue);
    });

    test('Firebase email-already-in-use goes under the email field', () {
      final e = FirebaseAuthException(code: 'email-already-in-use');
      expect(
        ErrorMessages.forField(e, 'email'),
        'An account already exists for that email.',
      );
      expect(ErrorMessages.isOnlyFieldError(e), isTrue);
    });

    test('server errors use the generic text', () {
      const e = ApiException(code: 'INTERNAL_ERROR', message: 'Traceback...');
      expect(ErrorMessages.of(e), ErrorMessages.generic);
    });
  });

  test('AppUser accepts a null email', () {
    final user = AppUser.fromJson({'id': 'u1', 'email': null});
    expect(user.email, '');
  });
}
