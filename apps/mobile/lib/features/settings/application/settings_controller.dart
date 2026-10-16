import 'package:riverpod_annotation/riverpod_annotation.dart';

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

/// The app version shown in Settings > About.
@riverpod
Future<String> appVersion(Ref ref) =>
    ref.watch(settingsRepositoryProvider).appVersion();
