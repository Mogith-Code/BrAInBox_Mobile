import 'package:dio/dio.dart';

import 'demo_engine.dart';

/// Demo mode's only hook into networking. Registered FIRST on the
/// [ApiClient]'s Dio, so an AI request it answers never gets a login token
/// and never opens a connection. Everything else goes to the real backend.
class DemoAiInterceptor extends Interceptor {
  DemoAiInterceptor(this.engine);

  final DemoEngine engine;

  /// Marks the engine's own lookups (e.g. a topic's code) so they skip demo
  /// handling and go straight to the backend.
  static const internalKey = 'demo_internal';
  static const _mergeKey = 'demo_merge';
  static const _fallbackKey = 'demo_fallback';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[internalKey] == true) {
      handler.next(options);
      return;
    }
    DemoAction action;
    try {
      action = await engine.handle(options);
    } catch (_) {
      action = DemoServe.error(
        500,
        'DEMO_ERROR',
        'The saved demo answer could not be opened. Please try again.',
      );
    }
    switch (action) {
      case DemoServe(:final status, :final data):
        final response = Response<dynamic>(
          requestOptions: options,
          statusCode: status,
          data: data,
        );
        if (status >= 400) {
          handler.reject(
            DioException.badResponse(
              statusCode: status,
              requestOptions: options,
              response: response,
            ),
          );
        } else {
          handler.resolve(response);
        }
      case DemoPass(:final body, :final merge, :final fallback):
        if (body != null) options.data = body;
        if (merge != null) options.extra[_mergeKey] = merge;
        if (fallback != null) options.extra[_fallbackKey] = fallback;
        handler.next(options);
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    if (options.extra[internalKey] != true) {
      engine.observe(response.data);
      final merge = options.extra[_mergeKey];
      if (merge is Object? Function(Object?)) {
        response.data = merge(response.data);
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final fallback = err.requestOptions.extra[_fallbackKey];
    // A 401 is left to the auth interceptor (token refresh).
    if (fallback is DemoServe? Function() && err.response?.statusCode != 401) {
      final served = fallback();
      if (served != null && served.status < 400) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: err.requestOptions,
            statusCode: served.status,
            data: served.data,
          ),
        );
        return;
      }
    }
    handler.next(err);
  }
}
