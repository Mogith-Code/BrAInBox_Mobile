import 'package:flutter/foundation.dart';

/// Build-time settings, passed with `--dart-define=KEY=value`.
///
/// Example:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
/// ```
abstract final class Env {
  static const String _apiBaseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const bool _disableAuthGuardDefine = bool.fromEnvironment(
    'DISABLE_AUTH_GUARD',
  );

  /// Base URL of the FastAPI backend, including the `/api/v1` prefix.
  ///
  /// When `API_BASE_URL` is not passed:
  /// - Android emulator: `http://10.0.2.2:8000/api/v1`
  ///   (10.0.2.2 is how the emulator reaches your computer's localhost)
  /// - Web (admin portal): `http://localhost:8000/api/v1`
  static String get apiBaseUrl {
    if (_apiBaseUrlDefine.isNotEmpty) return _apiBaseUrlDefine;
    return kIsWeb
        ? 'http://localhost:8000/api/v1'
        : 'http://10.0.2.2:8000/api/v1';
  }

  /// Debug helper: `--dart-define=DISABLE_AUTH_GUARD=true` lets you open any
  /// route without signing in. Always `false` in release builds.
  static bool get disableAuthGuard => kDebugMode && _disableAuthGuardDefine;
}
