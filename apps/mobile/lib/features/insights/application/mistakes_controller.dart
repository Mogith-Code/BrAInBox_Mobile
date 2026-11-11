import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/mistakes_repository.dart';
import '../domain/mistake_models.dart';

part 'mistakes_controller.g.dart';

/// One tab of the mistake journal ("To fix" or "Fixed").
@riverpod
class MistakesController extends _$MistakesController {
  @override
  Future<List<MistakeEntry>> build(MistakeTab tab) =>
      ref.watch(mistakesRepositoryProvider).mistakes(tab);

  /// "Fixed" toggle: the card leaves this tab at once (and comes back if
  /// the save fails). Returns false when it failed.
  Future<bool> setResolved(String id, {required bool resolved}) async {
    final before = state.value;
    if (before == null) return false;
    state = AsyncData([...before.where((m) => m.id != id)]);
    try {
      await ref
          .read(mistakesRepositoryProvider)
          .setResolved(id, resolved: resolved);
      // The other tab now has it.
      ref.invalidate(
        mistakesControllerProvider(
          tab == MistakeTab.open ? MistakeTab.resolved : MistakeTab.open,
        ),
      );
      return true;
    } catch (_) {
      if (ref.mounted) state = AsyncData(before);
      return false;
    }
  }
}
