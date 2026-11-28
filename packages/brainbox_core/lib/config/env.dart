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

  static const bool _useFakeApiDefine = bool.fromEnvironment('USE_FAKE_API');

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

  /// Debug helper: `--dart-define=USE_FAKE_API=true` swaps every repository
  /// for an in-memory fake (no backend, no Firebase needed), with the data
  /// from the Figma designs. Always `false` in release builds.
  static bool get useFakeApi => kDebugMode && _useFakeApiDefine;

  static const bool _demoAiDefine = bool.fromEnvironment('DEMO_AI');

  /// Viva helper: `--dart-define=DEMO_AI=true` answers the student app's AI
  /// features from saved demo data bundled in the app, while sign-in and
  /// every non-AI feature still use the real backend. Works in release
  /// builds too. The app shows a "Demo data" label while it is on.
  static bool get demoAi => _demoAiDefine;

  /// Throws when build flags that cannot work together are set.
  /// `DEMO_AI` needs the real backend and Firebase; `USE_FAKE_API` replaces
  /// both, so the two are never allowed at the same time.
  static void checkFlags() {
    if (_demoAiDefine && _useFakeApiDefine) {
      throw StateError(
        'DEMO_AI=true and USE_FAKE_API=true cannot be used together. '
        'DEMO_AI uses the real backend and Firebase; USE_FAKE_API replaces '
        'them. Remove one of the two --dart-define flags.',
      );
    }
  }
}
