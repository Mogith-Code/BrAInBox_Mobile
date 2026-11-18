import 'dart:convert';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Keeps the last JSON of read-only screens (syllabus, notes, short notes)
/// in a Hive box so they still open offline.
///
/// `main.dart` opens the box. When it is not open (tests, web before init)
/// every call just goes to the network.
class OfflineCache {
  const OfflineCache();

  static const boxName = 'offline_cache';

  static Future<void> open() => Hive.openBox<String>(boxName);

  Box<String>? get _box =>
      Hive.isBoxOpen(boxName) ? Hive.box<String>(boxName) : null;

  /// Runs [fetch]; on success saves the JSON under [key]. When the phone is
  /// offline, returns the saved JSON instead (or rethrows if none).
  Future<T> getJson<T>(String key, Future<T> Function() fetch) async {
    try {
      final value = await fetch();
      await _box?.put(key, jsonEncode(value));
      return value;
    } on ApiException catch (e) {
      final saved = e.isOffline ? _box?.get(key) : null;
      if (saved == null) rethrow;
      return jsonDecode(saved) as T;
    }
  }

  /// Removes everything (log out, account deleted).
  Future<void> clear() async => _box?.clear();
}

final offlineCacheProvider = Provider<OfflineCache>(
  (ref) => const OfflineCache(),
);
