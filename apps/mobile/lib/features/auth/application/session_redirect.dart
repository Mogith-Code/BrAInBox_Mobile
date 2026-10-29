import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import 'session_controller.dart';

/// The onboarding redirect table, as one pure function (easy to test).
///
/// | State                                         | Goes to              |
/// |-----------------------------------------------|----------------------|
/// | first launch, welcome not seen                | Welcome carousel     |
/// | not signed in                                 | Log in               |
/// | signed in, email not verified                 | Check your inbox     |
/// | verified, profile not completed               | Setup (resume step)  |
/// | profile done, diagnostic not done nor skipped | Let's find your ...  |
/// | otherwise                                     | Home                 |
///
/// Returns where to go, or null to stay on [location].
String? sessionRedirect(AsyncValue<SessionState> session, String location) {
  // Still loading (first start, or a refresh after signing in): stay put.
  // The splash screen shows a loader meanwhile.
  if (session.isLoading) return null;

  // Couldn't load the session (backend down...): the splash screen shows
  // the error with a Retry button.
  if (session.hasError) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final state = session.requireValue;
  return isAllowed(state, location) ? null : targetFor(state);
}

/// Where the student belongs right now.
String targetFor(SessionState s) {
  if (!s.signedIn) {
    return s.welcomeSeen ? AppRoutes.login : AppRoutes.onboarding;
  }
  if (!s.emailVerified) return AppRoutes.verifyEmail;
  if (!s.profileCompleted) return AppRoutes.profileSetup;
  if (!s.diagnosticDone) return AppRoutes.diagnostic;
  return AppRoutes.home;
}

/// Whether [location] may stay open in state [s].
bool isAllowed(SessionState s, String location) {
  // Splash always moves on once the session is known.
  if (location == AppRoutes.splash) return false;

  if (!s.signedIn) return AppRoutes.signedOutRoutes.contains(location);
  if (!s.emailVerified) return location == AppRoutes.verifyEmail;
  if (!s.profileCompleted) return location == AppRoutes.profileSetup;
  if (!s.diagnosticDone) return AppRoutes.diagnosticRoutes.contains(location);

  // Fully onboarded: anything except the sign-in / first-run screens.
  return !AppRoutes.signedOutRoutes.contains(location) &&
      location != AppRoutes.verifyEmail &&
      location != AppRoutes.profileSetup;
}
