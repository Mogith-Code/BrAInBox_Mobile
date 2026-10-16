import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs before every test in this package.
///
/// Tests have no internet, so google_fonts must not try to download Poppins /
/// Inter. Text then falls back to the test font (google_fonts may print a
/// "unable to load font" note - that is expected in tests).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
