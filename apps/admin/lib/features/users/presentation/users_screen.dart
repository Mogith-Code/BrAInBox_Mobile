import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/users_controller.dart';

/// Users screen - Student list with search; suspend / unsuspend.
///
/// Route: `/users`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usersControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(usersControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'Users',
        owner: 'Mogith',
        description:
            'Student list with search; suspend / unsuspend.\n${summary.message}',
      ),
    );
  }
}
