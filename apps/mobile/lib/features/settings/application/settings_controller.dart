import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_flow_controllers.dart';
import '../../auth/application/session_controller.dart';
import '../../home/application/home_controller.dart';
import '../../practice/application/diagnostic_controller.dart';
import '../../profile/application/profile_overview_controller.dart';
import '../data/settings_repository.dart';
import '../domain/settings_models.dart';

part 'settings_controller.g.dart';

/// Settings > Notifications. Each switch saves at once and goes back if
/// the save fails.
@riverpod
class SettingsController extends _$SettingsController {
  @override
  Future<NotificationSettings> build() =>
      ref.watch(settingsRepositoryProvider).notifications();

  /// Returns false when saving failed (the switch moves back).
  Future<bool> save(NotificationSettings next) async {
    final before = state.value;
    state = AsyncData(next);
    try {
      final saved = await ref
          .read(settingsRepositoryProvider)
          .saveNotifications(next);
      if (ref.mounted) state = AsyncData(saved);
      return true;
    } catch (_) {
      if (ref.mounted && before != null) state = AsyncData(before);
      return false;
    }
  }
}

/// Data & privacy (Figma F3), saved the same way.
@riverpod
class PrivacyController extends _$PrivacyController {
  @override
  Future<PrivacySettings> build() =>
      ref.watch(settingsRepositoryProvider).privacy();

  Future<bool> save(PrivacySettings next) async {
    final before = state.value;
    state = AsyncData(next);
    try {
      final saved = await ref
          .read(settingsRepositoryProvider)
          .savePrivacy(next);
      if (ref.mounted) state = AsyncData(saved);
      return true;
    } catch (_) {
      if (ref.mounted && before != null) state = AsyncData(before);
      return false;
    }
  }
}

/// Light or dark theme, read by the app widget (saved on the phone).
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.light;
  }

  Future<void> _load() async {
    final dark = await ref.read(themeModeStoreProvider).isDark();
    if (ref.mounted && dark) state = ThemeMode.dark;
  }

  Future<void> setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    await ref.read(themeModeStoreProvider).setDark(dark);
  }
}

/// Log out: Firebase sign out, then forget everything kept in memory for
/// this student. The router's redirect then shows Log in.
@riverpod
class LogoutController extends _$LogoutController {
  @override
  FutureOr<void> build() {}

  Future<void> logout() async {
    final session = ref.read(sessionProvider.notifier);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      // Clear cached data first so nothing of this student stays around.
      ref
        ..invalidate(diagnosticControllerProvider)
        ..invalidate(resetFlowProvider)
        ..invalidate(homeControllerProvider)
        ..invalidate(profileOverviewControllerProvider)
        ..invalidate(settingsControllerProvider)
        ..invalidate(privacyControllerProvider);
      // TODO(samni): also clear the Hive boxes once the app opens any.
      await session.signOut();
    });
    if (ref.mounted) state = result;
  }
}

/// The app version shown in Settings > About.
@riverpod
Future<String> appVersion(Ref ref) =>
    ref.watch(settingsRepositoryProvider).appVersion();
