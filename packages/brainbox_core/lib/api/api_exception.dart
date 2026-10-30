import 'package:dio/dio.dart';

/// The error every failed API call throws.
///
/// The backend sends errors in this shape:
/// ```json
/// {"error": {"code": "topic_not_found", "message": "Topic not found."}}
/// ```
/// [message] is safe to show to the student.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.retryAfter,
    this.details = const {},
  });

  /// Converts a Dio error into an [ApiException].
  factory ApiException.fromDioException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // 1. The backend's own error format.
    if (data is Map && data['error'] is Map) {
      final error = Map<String, dynamic>.from(data['error'] as Map);
      return ApiException(
        code: '${error['code'] ?? 'unknown'}',
        message: '${error['message'] ?? _genericMessage}',
        statusCode: status,
        retryAfter: _readRetryAfter(error, e.response?.headers),
        details: error,
      );
    }

    // 2. No backend error body: network problems, timeouts, etc.
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ApiException(
        code: 'timeout',
        message: 'The server took too long to respond. Please try again.',
        statusCode: status,
      ),
      DioExceptionType.connectionError => const ApiException(
        code: 'network',
        message: 'Cannot reach the server. Check your internet connection.',
      ),
      DioExceptionType.cancel => const ApiException(
        code: 'cancelled',
        message: 'The request was cancelled.',
      ),
      _ => ApiException(
        code: 'http_${status ?? 'unknown'}',
        message: _genericMessage,
        statusCode: status,
      ),
    };
  }

  static const _genericMessage = 'Something went wrong. Please try again.';

  /// `retry_after` (seconds) can be in the error body, in `error.details`,
  /// or in the `Retry-After` header. Returns null when none is given.
  static int? _readRetryAfter(Map<String, dynamic> error, Headers? headers) {
    final details = error['details'];
    final value =
        error['retry_after'] ??
        (details is Map ? details['retry_after'] : null) ??
        headers?.value('retry-after');
    if (value is int) return value;
    return int.tryParse('${value ?? ''}');
  }

  /// Machine-readable code from the backend, e.g. `topic_not_found`.
  final String code;

  /// Human-readable message, safe to show in the UI.
  final String message;

  /// HTTP status code, if the server answered.
  final int? statusCode;

  /// Seconds to wait before trying again (429 responses), if the server said.
  final int? retryAfter;

  /// The raw `error` object from the backend (extra fields live here).
  final Map<String, dynamic> details;

  /// `CODE_INVALID` only: how many wrong tries are left before the code dies.
  int? get attemptsLeft {
    final value = details['attempts_left'];
    return value is int ? value : null;
  }

  /// Which form field each problem belongs to, e.g. `{'phone': '...'}`.
  ///
  /// From the error code (`INVALID_PHONE` -> phone, `WEAK_PASSWORD` ->
  /// password, `CONSENT_REQUIRED` -> consent, `EMAIL_IN_USE` -> email) or,
  /// for `VALIDATION_ERROR`, from `details: [{field: "body.phone", ...}]`.
  Map<String, String> get fieldErrors {
    final byCode = switch (code) {
      'INVALID_PHONE' => 'phone',
      'WEAK_PASSWORD' => 'password',
      'CONSENT_REQUIRED' => 'consent',
      'EMAIL_IN_USE' => 'email',
      _ => null,
    };
    if (byCode != null) return {byCode: message};

    final list = details['details'];
    if (code != 'VALIDATION_ERROR' || list is! List) return const {};
    return {
      for (final item in list.whereType<Map<dynamic, dynamic>>())
        '${item['field']}'.split('.').last: '${item['message']}',
    };
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
