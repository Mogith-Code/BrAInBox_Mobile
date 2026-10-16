import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// DEBUG ONLY: a list of every screen in the app, so you can open your
/// screen on a phone without clicking through the whole flow.
///
/// Open it from the "Dev menu" button on the splash or home screen.
/// The list comes from [AppRoutes.catalog].
class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = AppRoutes.catalog;
    return Scaffold(
      appBar: AppBar(title: const Text('Dev menu - all screens')),
      body: ListView.separated(
        itemCount: routes.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final route = routes[index];
          return ListTile(
            title: Text(route.title),
            subtitle: Text(
              '${route.path}  ·  ${route.owner}',
              style: const TextStyle(color: AppColors.muted),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(route.path),
          );
        },
      ),
    );
  }
}
