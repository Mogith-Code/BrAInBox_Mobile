import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import '../domain/profile_models.dart';

/// The saved setup answers (`GET /profile`), shown as summaries in
/// Settings > Profile. Refreshed after an edit is saved.
final savedProfileProvider = FutureProvider.autoDispose<Profile>(
  (ref) => ref.watch(profileRepositoryProvider).profile(),
);
