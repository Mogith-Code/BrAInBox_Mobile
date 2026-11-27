import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/demo/demo_mode.dart';
import 'features/offline/offline_cache.dart';
// Not committed (it holds Firebase keys). `melos bootstrap` creates a stub
// from firebase_options.dart.example; `flutterfire configure` replaces it
// with the real one. See README > Firebase setup.
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fails at once if DEMO_AI and USE_FAKE_API are both set.
  Env.checkFlags();

  // 1. Firebase. Safe if not configured yet: the app still starts, sign-in is
  //    disabled and a "Firebase not configured" strip shows in debug.
  await FirebaseSetup.initialize(() => DefaultFirebaseOptions.currentPlatform);

  // 2. Hive (offline cache for syllabus, notes and short notes).
  await Hive.initFlutter();
  await OfflineCache.open();

  // 3. ProviderScope holds every Riverpod provider.
  // retry: null -> a failing request shows its error (with a Retry button)
  // instead of Riverpod silently retrying it in the background.
  //    DEMO_AI=true only: AI features answer from saved demo data
  //    (lib/app/demo). With the flag off this loads nothing.
  final overrides = Env.demoAi ? await demoOverrides() : const <Override>[];
  runApp(
    ProviderScope(
      overrides: overrides,
      retry: (_, _) => null,
      child: const BrainBoxApp(),
    ),
  );
}
