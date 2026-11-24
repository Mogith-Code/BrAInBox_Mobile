import '../../features/offline/offline_cache.dart';
import '../../features/visuals/data/recent_visuals_store.dart';

/// [OfflineCache] that never saves a demo reply, so saved AI outputs can't
/// show up later in normal mode. Real replies are cached as usual.
class DemoSafeOfflineCache extends OfflineCache {
  DemoSafeOfflineCache(this._isDemo);

  final bool Function(Object? value) _isDemo;

  @override
  Future<T> getJson<T>(String key, Future<T> Function() fetch) async {
    try {
      return await super.getJson<T>(key, () async {
        final value = await fetch();
        if (_isDemo(value)) throw _DemoValue(value);
        return value;
      });
    } on _DemoValue catch (demo) {
      return demo.value as T;
    }
  }
}

class _DemoValue {
  const _DemoValue(this.value);

  final Object? value;
}

/// [RecentVisualsStore] that keeps demo visual ids in memory only; real ids
/// are still saved on the phone.
class DemoRecentVisualsStore extends RecentVisualsStore {
  final List<String> _demo = [];

  static bool _isDemo(String id) => id.startsWith('demo-');

  @override
  Future<List<String>> ids() async =>
      [..._demo, ...await super.ids()].take(RecentVisualsStore.max).toList();

  @override
  Future<void> add(String id) async {
    if (!_isDemo(id)) return super.add(id);
    _demo
      ..remove(id)
      ..insert(0, id);
  }

  @override
  Future<void> remove(Iterable<String> gone) async {
    _demo.removeWhere(gone.contains);
    await super.remove(gone.where((id) => !_isDemo(id)));
  }
}
