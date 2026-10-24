import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_repository.g.dart';

/// Stores whether the student has already seen the welcome carousel.
///
/// Only this harmless flag is stored on the device (shared_preferences).
/// Never store passwords, codes or tokens here.
class OnboardingRepository {
  static const _welcomeSeenKey = 'welcome_seen';

  Future<bool> isWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeSeenKey) ?? false;
  }

  Future<void> markWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeSeenKey, true);
  }
}

@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(Ref ref) => OnboardingRepository();
