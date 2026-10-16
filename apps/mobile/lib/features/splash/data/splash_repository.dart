import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/splash_models.dart';

part 'splash_repository.g.dart';

/// Data layer for the Splash feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class SplashRepository {
  SplashRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Splash screen.
  Future<SplashSummary> fetchSummary() async {
    // TODO(mogith): call the backend instead of returning placeholder data.
    // This feature has no backend endpoint yet.
    return const SplashSummary(
      title: 'Splash',
      message: 'Placeholder data - API not connected yet.',
    );
  }
}

@riverpod
SplashRepository splashRepository(Ref ref) =>
    SplashRepository(ref.watch(apiClientProvider));
