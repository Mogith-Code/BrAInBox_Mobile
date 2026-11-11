import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_controller.dart';
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
      // Settings > Dark mode (saved on the phone).
      themeMode: ref.watch(appThemeModeProvider),
      routerConfig: router,
      // Debug builds: a "FAKE API" corner ribbon with USE_FAKE_API=true,
      // otherwise "Firebase not configured" at the top if it isn't.
      builder: (context, child) {
        final app = child ?? const SizedBox.shrink();
        if (Env.useFakeApi) {
          return Banner(
            message: 'FAKE API',
            location: BannerLocation.topEnd,
            color: AppColors.primary,
            child: app,
          );
        }
        return FirebaseStatusBanner(child: app);
      },
    );
  }
}
