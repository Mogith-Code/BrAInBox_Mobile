import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/env.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

part 'api_client.g.dart';

/// The ONLY class that talks HTTP to the BrAInBox backend.
///
/// Flow: screen -> controller -> repository -> [ApiClient].
/// Repositories get it with `ref.watch(apiClientProvider)`.
///
/// Every method throws [ApiException] on failure.
class ApiClient {
  ApiClient({Dio? dio, IdTokenGetter? getIdToken})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: Env.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 60), // uploads can be big
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            ),
          ) {
    this.dio.interceptors.add(
      AuthInterceptor(dio: this.dio, getIdToken: getIdToken),
    );
    if (kDebugMode) {
      // Logs requests/responses in the debug console.
      // requestHeader is off so the ID token is never printed.
      this.dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          logPrint: (line) => debugPrint('$line'),
        ),
      );
    }
  }

  /// The underlying Dio instance (prefer the helpers below).
  final Dio dio;

  /// GET [path] and return the decoded JSON body.
  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send(() => dio.get<T>(path, queryParameters: query));

  /// POST [data] (usually a `Map`) as JSON to [path].
  Future<T> post<T>(String path, {Object? data, Map<String, dynamic>? query}) =>
      _send(() => dio.post<T>(path, data: data, queryParameters: query));

  /// PUT [data] as JSON to [path].
  Future<T> put<T>(String path, {Object? data}) =>
      _send(() => dio.put<T>(path, data: data));

  /// PATCH [data] as JSON to [path].
  Future<T> patch<T>(String path, {Object? data}) =>
      _send(() => dio.patch<T>(path, data: data));

  /// DELETE [path].
  Future<T> delete<T>(String path, {Object? data}) =>
      _send(() => dio.delete<T>(path, data: data));

  /// Multipart upload (notes PDFs, answer photos, past papers...).
  ///
  /// ```dart
  /// final form = FormData.fromMap({
  ///   'file': await MultipartFile.fromFile(path, filename: 'answer.jpg'),
  /// });
  /// await api.upload('/evaluations/handwritten', formData: form);
  /// ```
  Future<T> upload<T>(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
  }) => _send(
    () => dio.post<T>(path, data: formData, onSendProgress: onSendProgress),
  );

  Future<T> _send<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

/// One [ApiClient] for the whole app.
@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) => ApiClient();
