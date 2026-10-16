import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/splash_controller.dart';

/// Splash screen - Logo, then redirect based on sign-in and onboarding state.
///
/// Route: `/`
///
/// Shows the stacked logo on the brand gradient. It continues the native
/// splash (indigo + icon) that Android shows before Flutter starts.
///
// TODO(mogith): replace the "Get started" button with the automatic
// start-up redirect (onboarding / login / home). Keep this file UI-only.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splashControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // White status-bar icons on the dark gradient.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: SafeArea(
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    const Spacer(),
                    const _LogoEntrance(
                      child: AppLogo(
                        variant: AppLogoVariant.stacked,
                        size: 96,
                        onDark: true,
                        showTagline: true,
                      ),
                    ),
                    const Spacer(),
                    state.when(
                      loading: () => const SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.white,
                        ),
                      ),
                      error: (error, _) => ErrorBanner(
                        message: '$error',
                        onRetry: () => ref.invalidate(splashControllerProvider),
                      ),
                      data: (_) => FilledButton(
                        onPressed: () => context.go(AppRoutes.onboarding),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                        child: const Text('Get started'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Splash · Owner: Mogith · auto-redirect coming soon',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.taglineOnDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Leaves room for the debug "Dev menu" button.
                    if (kDebugMode) const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ),
        ),
        // DEBUG ONLY: jump to any screen while features are being built.
        floatingActionButton: kDebugMode
            ? FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.devMenu),
                icon: const Icon(Icons.developer_mode),
                label: const Text('Dev menu'),
              )
            : null,
      ),
    );
  }
}

/// Fades and scales the logo in once. Skipped when the user has turned on
/// "remove animations" / reduced motion in the system settings.
class _LogoEntrance extends StatelessWidget {
  const _LogoEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
      ),
      child: child,
    );
  }
}
