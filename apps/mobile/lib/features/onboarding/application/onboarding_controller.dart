import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/onboarding_repository.dart';

part 'onboarding_controller.g.dart';

/// `true` once the student has tapped Get Started, Skip or Log in on the
/// welcome carousel. The router's onboarding redirect watches this.
@Riverpod(keepAlive: true)
class WelcomeSeen extends _$WelcomeSeen {
  @override
  Future<bool> build() =>
      ref.watch(onboardingRepositoryProvider).isWelcomeSeen();

  /// Saves the flag so the carousel is not shown again.
  Future<void> markSeen() async {
    await ref.read(onboardingRepositoryProvider).markWelcomeSeen();
    state = const AsyncData(true);
  }
}
