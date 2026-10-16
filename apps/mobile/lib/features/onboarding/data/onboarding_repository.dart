import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/onboarding_models.dart';

part 'onboarding_repository.g.dart';

/// Data layer for the Onboarding feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class OnboardingRepository {
  OnboardingRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Onboarding screen.
  Future<OnboardingSummary> fetchSummary() async {
    // TODO(mogith): call the backend instead of returning placeholder data.
    // This feature has no backend endpoint yet.
    return const OnboardingSummary(
      title: 'Onboarding',
      message: 'Placeholder data - API not connected yet.',
    );
  }
}

@riverpod
OnboardingRepository onboardingRepository(Ref ref) =>
    OnboardingRepository(ref.watch(apiClientProvider));
