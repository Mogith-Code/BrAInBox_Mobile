import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

/// The root widget of the student app.
class BrainBoxApp extends ConsumerWidget {
  const BrainBoxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'BrAInBox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // TODO(samni): read the theme mode from the settings feature.
      themeMode: ThemeMode.light,
      routerConfig: router,
      // Shows "Firebase not configured" at the top in debug builds.
      builder: (context, child) =>
          FirebaseStatusBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
