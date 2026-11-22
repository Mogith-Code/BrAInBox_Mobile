import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/onboarding_repository.dart';

part 'onboarding_controller.g.dart';

/// `true` once the student has tapped Get Started, Skip or Log in on the
/// welcome carousel. The router's onboarding redirect watches this.
///
/// It starts as `false` on every app launch, so a signed-out student always
/// opens the app on the introduction. Signed-in students go straight in.
@Riverpod(keepAlive: true)
class WelcomeSeen extends _$WelcomeSeen {
  @override
  Future<bool> build() async => false;

  /// Moves on to Log in for the rest of this app launch.
  Future<void> markSeen() async {
    await ref.read(onboardingRepositoryProvider).markWelcomeSeen();
    state = const AsyncData(true);
  }
}
