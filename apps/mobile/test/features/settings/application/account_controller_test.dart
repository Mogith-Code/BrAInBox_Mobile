import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:brainbox_mobile/features/auth/application/auth_flow_controllers.dart';
import 'package:brainbox_mobile/features/auth/application/session_controller.dart';
import 'package:brainbox_mobile/features/offline/offline_cache.dart';
import 'package:brainbox_mobile/features/settings/application/account_controller.dart';
import 'package:brainbox_mobile/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../../../helpers/fake_app.dart';

void main() {
  late Directory dir;
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('bb_hive');
    Hive.init(dir.path);
    await OfflineCache.open();
  });
  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('download my data saves the export as a JSON file', () async {
    String? name;
    Uint8List? bytes;
    final c = fakeContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        fileSaverProvider.overrideWithValue((n, b) async {
          name = n;
          bytes = b;
          return true;
        }),
      ],
    );
    addTearDown(c.dispose);
    final sub = c.listen(accountControllerProvider, (_, _) {});
    addTearDown(sub.close);

    await c.read(accountControllerProvider.notifier).exportData();

    expect(c.read(accountControllerProvider).action, AccountAction.exported);
    expect(name, startsWith('brainbox-my-data-'));
    final json = jsonDecode(utf8.decode(bytes!)) as Map<String, dynamic>;
    expect(json.keys, containsAll(['notifications', 'privacy']));
  });

  test('delete account removes it, clears the cache and signs out', () async {
    final c = fakeContainer();
    addTearDown(c.dispose);
    final login = c.listen(loginControllerProvider, (_, _) {});
    addTearDown(login.close);
    await c
        .read(loginControllerProvider.notifier)
        .submit(email: 'nethmi.p@gmail.com', password: 'Mito2027');
    await Hive.box<String>(OfflineCache.boxName).put('k', '"v"');

    final sub = c.listen(accountControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final ok = await c.read(accountControllerProvider.notifier).deleteAccount();

    expect(ok, isTrue);
    expect(Hive.box<String>(OfflineCache.boxName).isEmpty, isTrue);
    expect((await c.read(sessionProvider.future)).signedIn, isFalse);
  });

  group('OfflineCache', () {
    const cache = OfflineCache();
    const offline = ApiException(code: 'network', message: 'offline');

    test('returns saved JSON when offline', () async {
      expect(await cache.getJson('a', () async => {'x': 1}), {'x': 1});
      expect(await cache.getJson<Object?>('a', () => throw offline), {'x': 1});
    });

    test('rethrows when offline with nothing saved, or on other errors', () {
      expect(
        cache.getJson<Object?>('missing', () => throw offline),
        throwsA(isA<ApiException>()),
      );
      expect(
        cache.getJson<Object?>(
          'a',
          () => throw const ApiException(code: 'x', message: 'bad'),
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
