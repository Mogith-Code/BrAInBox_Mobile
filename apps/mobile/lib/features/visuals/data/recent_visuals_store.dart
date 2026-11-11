import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'recent_visuals_store.g.dart';

/// Remembers the ids of the visuals made on this phone, newest first, so
/// "My visuals" can list them even when they belong to no topic.
///
/// The backend has no "my visuals" endpoint yet; each id is loaded with
/// `GET /visuals/{id}`.
// TODO(mogith): use GET /visuals/mine once the backend has it.
class RecentVisualsStore {
  static const _key = 'recent_visual_ids';

  /// Only the newest ones are kept.
  static const max = 20;

  Future<List<String>> ids() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  /// Puts [id] first (once) and drops the oldest past [max].
  Future<void> add(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = [
      id,
      ...?prefs.getStringList(_key)?.where((i) => i != id),
    ].take(max).toList();
    await prefs.setStringList(_key, ids);
  }

  /// Forgets ids the backend no longer has (deleted, or not ours).
  Future<void> remove(Iterable<String> gone) async {
    final prefs = await SharedPreferences.getInstance();
    final drop = gone.toSet();
    final ids = [
      ...?prefs.getStringList(_key)?.where((i) => !drop.contains(i)),
    ];
    await prefs.setStringList(_key, ids);
  }
}

@Riverpod(keepAlive: true)
RecentVisualsStore recentVisualsStore(Ref ref) => RecentVisualsStore();
