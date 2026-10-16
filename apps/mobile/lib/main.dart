import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
// Not committed (it holds Firebase keys). `melos bootstrap` creates a stub
// from firebase_options.dart.example; `flutterfire configure` replaces it
// with the real one. See README > Firebase setup.
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase. Safe if not configured yet: the app still starts, sign-in is
  //    disabled and a "Firebase not configured" strip shows in debug.
  await FirebaseSetup.initialize(() => DefaultFirebaseOptions.currentPlatform);

  // 2. Hive (offline cache).
  // TODO(samni): open the boxes the app needs, e.g.
  //   await Hive.openBox<String>('notes_cache');
  await Hive.initFlutter();

  // 3. ProviderScope holds every Riverpod provider.
  runApp(const ProviderScope(child: BrainBoxApp()));
}
