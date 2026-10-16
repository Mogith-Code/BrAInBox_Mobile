import 'package:brainbox_core/brainbox_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/settings_models.dart';

part 'settings_repository.g.dart';

/// Data layer for the Settings feature.
///
/// The ONLY place in this feature that calls the backend (through
/// [ApiClient]). Controllers call this; screens never do.
class SettingsRepository {
  SettingsRepository(this.api);

  final ApiClient api;

  /// Loads the data for the main Settings screen.
  Future<SettingsSummary> fetchSummary() async {
    // TODO(samni): call the backend instead of returning placeholder data.
    // Real version (uncomment when the endpoint exists):
    // final json = await api.get<Map<String, dynamic>>('/me/settings');
    // return SettingsSummary.fromJson(json);
    return const SettingsSummary(
      title: 'Settings',
      message: 'Placeholder data - API not connected yet.',
    );
  }

  /// The installed app version for Settings > About, e.g. "0.1.0 (1)".
  Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  // TODO(samni): add one method per endpoint, e.g.
  //   PUT /me/settings  ->  Save settings
  //   DELETE /me  ->  Delete account (privacy)
}

@riverpod
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(apiClientProvider));
