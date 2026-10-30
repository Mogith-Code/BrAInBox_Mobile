import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_flow_controllers.dart';
import '../../auth/application/session_controller.dart';
import '../../home/application/home_controller.dart';
import '../../practice/application/diagnostic_controller.dart';

import '../data/settings_repository.dart';
import '../domain/settings_models.dart';

part 'settings_controller.g.dart';

/// State for the Settings feature.
///
/// The state is an `AsyncValue<SettingsSummary>`, so the screen gets loading,
/// error and data cases for free:
/// ```dart
/// final state = ref.watch(settingsControllerProvider);
/// state.when(loading: ..., error: ..., data: ...);
/// ```
@riverpod
class SettingsController extends _$SettingsController {
  @override
  Future<SettingsSummary> build() {
    // TODO(samni): load what the screen needs on open.
    return ref.watch(settingsRepositoryProvider).fetchSummary();
  }

  /// Reloads the data (pull-to-refresh, Retry button...).
  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(settingsRepositoryProvider).fetchSummary(),
    );
    if (ref.mounted) state = next;
  }

  // TODO(samni): add one method per user action (submit, delete, generate...).
  // Each one calls the repository and updates `state`.
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
        ..invalidate(homeControllerProvider);
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
