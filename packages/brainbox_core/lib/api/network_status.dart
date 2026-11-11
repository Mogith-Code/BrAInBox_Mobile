import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_status.g.dart';

/// Whether the backend could be reached last time we tried (true = online).
///
/// [ApiClient] reports every answer (online) and every "cannot connect"
/// (offline), so the app can show "You're offline" without a plugin.
@Riverpod(keepAlive: true)
class NetworkStatus extends _$NetworkStatus {
  @override
  bool build() => true;

  void report({required bool online}) {
    if (state != online) state = online;
  }
}

/// Tells [NetworkStatus] about each request's outcome.
class NetworkStatusInterceptor extends Interceptor {
  NetworkStatusInterceptor(this.onStatus);

  final void Function(bool online) onStatus;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    onStatus(true);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final offline =
        err.response == null &&
        (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout);
    // Any answer from the server (even a 500) means we are online.
    onStatus(!offline);
    handler.next(err);
  }
}
