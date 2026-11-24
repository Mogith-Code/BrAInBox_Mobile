import 'package:brainbox_core/brainbox_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../features/offline/offline_cache.dart';
import '../../features/visuals/data/recent_visuals_store.dart';
import 'demo_ai_interceptor.dart';
import 'demo_engine.dart';
import 'demo_seed.dart';
import 'demo_storage.dart';

/// Turns demo mode on for the whole app (`--dart-define=DEMO_AI=true`).
///
/// `main.dart` calls this ONLY when [Env.demoAi] is true, so with the flag
/// off nothing here runs: no seed files are read and no interceptor is
/// registered. To remove demo mode, delete `lib/app/demo/`,
/// `assets/demo/` and the few lines that call into them.
Future<List<Override>> demoOverrides({
  AssetBundle? bundle,
  DemoTiming timing = const DemoTiming(),
}) async {
  final seed = await DemoSeed.load(bundle ?? rootBundle);
  final engine = DemoEngine(seed, timing: timing);
  return [
    demoEngineProvider.overrideWithValue(engine),
    apiClientProvider.overrideWith((ref) {
      final client = ApiClient(
        onNetworkStatus: (online) =>
            ref.read(networkStatusProvider.notifier).report(online: online),
        leadingInterceptors: [DemoAiInterceptor(engine)],
      );
      engine.realGet = demoRealGet(client.dio);
      return client;
    }),
    offlineCacheProvider.overrideWithValue(
      DemoSafeOfflineCache(engine.isDemoData),
    ),
    recentVisualsStoreProvider.overrideWithValue(DemoRecentVisualsStore()),
  ];
}

/// Non-AI lookups the demo needs (a topic's code, a question's text). They
/// go to the real backend with the normal login token.
DemoRealGet demoRealGet(Dio dio) => (path) async {
  try {
    final response = await dio.get<Object?>(
      path,
      options: Options(extra: {DemoAiInterceptor.internalKey: true}),
    );
    final data = response.data;
    return data is Map ? Map<String, dynamic>.from(data) : null;
  } catch (_) {
    return null;
  }
};

/// The running demo engine, or null when demo mode is off.
final demoEngineProvider = Provider<DemoEngine?>((ref) => null);
