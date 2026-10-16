import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Starts Firebase and remembers whether it worked.
///
/// Until someone runs `flutterfire configure`, the apps use a stub
/// `firebase_options.dart` that throws. We catch that here so the apps still
/// start: sign-in is disabled and a "Firebase not configured" strip is shown
/// in debug builds (see `FirebaseStatusBanner`).
abstract final class FirebaseSetup {
  static bool _isReady = false;

  /// `true` once `Firebase.initializeApp` succeeded.
  static bool get isReady => _isReady;

  /// Call once in `main()` before `runApp`. Never throws.
  ///
  /// [options] is normally `() => DefaultFirebaseOptions.currentPlatform`.
  static Future<bool> initialize(FirebaseOptions Function() options) async {
    try {
      await Firebase.initializeApp(options: options());
      _isReady = true;
    } catch (error) {
      _isReady = false;
      debugPrint(
        '[BrAInBox] Firebase not configured, auth is disabled. '
        'Run `flutterfire configure` (see README). Details: $error',
      );
    }
    return _isReady;
  }
}
