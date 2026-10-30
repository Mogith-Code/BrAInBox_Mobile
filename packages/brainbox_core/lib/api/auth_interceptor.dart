import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/firebase_setup.dart';

/// Returns the current Firebase ID token, or `null` when signed out.
typedef IdTokenGetter = Future<String?> Function({bool forceRefresh});

/// Adds `Authorization: Bearer <Firebase ID token>` to every request.
///
/// The backend verifies this token. If the backend answers 401
/// `INVALID_TOKEN` (token expired), we refresh the token ONCE and retry the
/// request. Other 401s (e.g. `USER_NOT_REGISTERED`) and a second 401 are
/// passed on to the caller as an error.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, IdTokenGetter? getIdToken})
    : _getIdToken = getIdToken ?? firebaseIdToken;

  /// The Dio instance this interceptor is attached to (used for the retry).
  final Dio dio;
  final IdTokenGetter _getIdToken;

  /// Marks a request that was already retried, so we never loop.
  static const _retriedKey = 'auth_retried';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _safeToken(forceRefresh: false);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final alreadyRetried = request.extra[_retriedKey] == true;

    if (!isExpiredToken(err.response) || alreadyRetried) {
      handler.next(err);
      return;
    }

    // The token probably expired: force a fresh one and retry once.
    final token = await _safeToken(forceRefresh: true);
    if (token == null) {
      handler.next(err);
      return;
    }

    request.headers['Authorization'] = 'Bearer $token';
    request.extra[_retriedKey] = true;
    try {
      final response = await dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// A 401 that a fresh token can fix: `INVALID_TOKEN` (expired, revoked).
  /// A 401 without our error body counts too (e.g. from a proxy).
  static bool isExpiredToken(Response<dynamic>? response) {
    if (response?.statusCode != 401) return false;
    final data = response?.data;
    final error = data is Map ? data['error'] : null;
    return error is! Map || error['code'] == 'INVALID_TOKEN';
  }

  /// Getting a token can fail (offline, etc.). Then we send no token and let
  /// the backend answer 401.
  Future<String?> _safeToken({required bool forceRefresh}) async {
    try {
      return await _getIdToken(forceRefresh: forceRefresh);
    } catch (_) {
      return null;
    }
  }
}

/// Default [IdTokenGetter]: reads the token from Firebase Auth.
Future<String?> firebaseIdToken({bool forceRefresh = false}) async {
  if (!FirebaseSetup.isReady) return null; // Firebase not configured yet.
  return FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);
}
