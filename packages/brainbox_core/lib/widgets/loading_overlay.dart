import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Puts a dimmed spinner on top of [child] while [isLoading] is true and
/// blocks taps underneath (e.g. while signing in).
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) ...[
          const ModalBarrier(dismissible: false, color: Colors.black26),
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(message!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
