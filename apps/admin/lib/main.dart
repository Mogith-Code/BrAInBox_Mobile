import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
// Not committed (it holds Firebase keys). `melos bootstrap` creates a stub
// from firebase_options.dart.example; `flutterfire configure` replaces it
// with the real one. See README > Firebase setup.
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safe if not configured yet: the portal still starts, sign-in is disabled
  // and a "Firebase not configured" strip shows in debug.
  await FirebaseSetup.initialize(() => DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: BrainBoxAdminApp()));
}
