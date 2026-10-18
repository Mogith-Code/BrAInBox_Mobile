import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../auth/application/session_controller.dart';
import 'widgets/splash_decorations.dart';

/// Splash (Figma A1): brand gradient, logo, "BrAInBox",
/// "Study smarter. Fix what matters." and a loader.
///
/// Route: `/`. While the session loads (welcome flag, Firebase, GET
/// /auth/me) it shows the dots; then the router's onboarding redirect moves
/// on by itself. If loading fails it shows the error with Retry.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final guardOn = ref.watch(authGuardEnabledProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: Stack(
            children: [
              const SplashDecorations(),
              SafeArea(
                child: SizedBox.expand(
                  child: Column(
                    children: [
                      const Spacer(flex: 5),
                      const _LogoEntrance(child: _GlassLogo()),
                      const SizedBox(height: AppSpacing.xl),
                      const _LogoEntrance(
                        child: AppLogo(
                          variant: AppLogoVariant.wordmark,
                          size: 120,
                          onDark: true,
                          showTagline: true,
                        ),
                      ),
                      const Spacer(flex: 6),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          0,
                          AppSpacing.xl,
                          AppSpacing.xxl + AppSpacing.lg,
                        ),
                        child: _Bottom(session: session, guardOn: guardOn),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loader, error + Retry, or (with the redirect switched off) buttons.
class _Bottom extends ConsumerWidget {
  const _Bottom({required this.session, required this.guardOn});

  final AsyncValue<SessionState> session;
  final bool guardOn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session.hasError && !session.isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ErrorMessages.of(session.error),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          _WhiteButton(
            label: 'Retry',
            onPressed: () => ref.read(sessionProvider.notifier).refresh(),
          ),
        ],
      );
    }

    // No redirect (no Firebase and no fake API, or DISABLE_AUTH_GUARD):
    // let the developer move on by hand.
    if (!guardOn) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WhiteButton(
            label: 'Get started',
            onPressed: () => context.go(AppRoutes.onboarding),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.devMenu),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.developer_mode),
              label: const Text('Dev menu'),
            ),
          ],
        ],
      );
    }

    return const LoadingDots();
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// The app icon inside a frosted rounded square.
class _GlassLogo extends StatelessWidget {
  const _GlassLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.32)),
      ),
      child: const AppLogo(size: 100),
    );
  }
}

/// Fades and scales the logo in once (skipped with reduced motion).
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
        child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
      ),
      child: child,
    );
  }
}
