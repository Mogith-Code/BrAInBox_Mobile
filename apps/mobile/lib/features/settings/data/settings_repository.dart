import 'package:brainbox_core/brainbox_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings_models.dart';

part 'settings_repository.g.dart';

/// Settings and privacy. Only this layer calls the API.
abstract interface class SettingsRepository {
  /// `GET /settings`
  Future<NotificationSettings> notifications();

  /// `PATCH /settings` with the changed fields.
  Future<NotificationSettings> saveNotifications(NotificationSettings value);

  /// `GET /privacy`
  Future<PrivacySettings> privacy();

  /// `PATCH /privacy`
  Future<PrivacySettings> savePrivacy(PrivacySettings value);

  /// The installed app version for Settings > About, e.g. "0.1.0 (1)".
  Future<String> appVersion();
}

class ApiSettingsRepository implements SettingsRepository {
  ApiSettingsRepository(this.api);

  final ApiClient api;

  @override
  Future<NotificationSettings> notifications() async =>
      NotificationSettings.fromJson(
        await api.get<Map<String, dynamic>>('/settings'),
      );

  @override
  Future<NotificationSettings> saveNotifications(
    NotificationSettings value,
  ) async => NotificationSettings.fromJson(
    await api.patch<Map<String, dynamic>>('/settings', data: value.toJson()),
  );

  @override
  Future<PrivacySettings> privacy() async =>
      PrivacySettings.fromJson(await api.get<Map<String, dynamic>>('/privacy'));

  @override
  Future<PrivacySettings> savePrivacy(PrivacySettings value) async =>
      PrivacySettings.fromJson(
        await api.patch<Map<String, dynamic>>('/privacy', data: value.toJson()),
      );

  @override
  Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}

/// DEBUG ONLY (`USE_FAKE_API=true`): kept in memory.
class FakeSettingsRepository implements SettingsRepository {
  NotificationSettings _notifications = const NotificationSettings();
  PrivacySettings _privacy = const PrivacySettings(shareResearch: false);

  @override
  Future<NotificationSettings> notifications() async => _notifications;

  @override
  Future<NotificationSettings> saveNotifications(
    NotificationSettings value,
  ) async => _notifications = value;

  @override
  Future<PrivacySettings> privacy() async => _privacy;

  @override
  Future<PrivacySettings> savePrivacy(PrivacySettings value) async =>
      _privacy = value.copyWith(personalisedRecommendations: true);

  @override
  Future<String> appVersion() async => '0.1.0 (fake)';
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => Env.useFakeApi
    ? FakeSettingsRepository()
    : ApiSettingsRepository(ref.watch(apiClientProvider));

/// Dark mode is a phone setting: kept on the device so the app starts in
/// the right theme even before sign in.
class ThemeModeStore {
  static const _key = 'dark_mode';

  Future<bool> isDark() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  Future<void> setDark(bool dark) async =>
      (await SharedPreferences.getInstance()).setBool(_key, dark);
}

@Riverpod(keepAlive: true)
ThemeModeStore themeModeStore(Ref ref) => ThemeModeStore();
