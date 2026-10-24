import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/onboarding_controller.dart';
import '../domain/onboarding_models.dart';
import 'widgets/welcome_illustrations.dart';

/// Welcome carousel (Figma A2-A4): 3 slides, Skip, dots, Get Started and
/// "I already have an account · Log in".
///
/// Route: `/onboarding`. Get Started, Skip and Log in all save the
/// "welcome seen" flag, so the carousel is shown only once.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _leaveTo(String route) async {
    await ref.read(welcomeSeenProvider.notifier).markSeen();
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    const slides = WelcomeSlide.all;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip (top right).
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                child: TextButton(
                  onPressed: () => _leaveTo(AppRoutes.signup),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    minimumSize: const Size(48, 48),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlidePage(slide: slides[i]),
              ),
            ),
            _Dots(count: slides.length, index: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              child: AppButton(
                label: 'Get Started',
                onPressed: () => _leaveTo(AppRoutes.signup),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Semantics(
                button: true,
                label: 'I already have an account. Log in',
                child: ExcludeSemantics(
                  child: TextButton(
                    onPressed: () => _leaveTo(AppRoutes.login),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      'I already have an account · Log in',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide});

  final WelcomeSlide slide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The illustration takes ~60% of the space on a 360x800 phone and
        // shrinks on short screens so the text always fits.
        final cardHeight = (constraints.maxHeight * 0.62).clamp(160.0, 360.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: cardHeight,
                width: double.infinity,
                child: ExcludeSemantics(
                  child: WelcomeIllustrationView(kind: slide.illustration),
                ),
              ),
              const SizedBox(height: AppSpacing.xl + 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        slide.title,
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      slide.body,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Page dots: the current one is a wide indigo pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Slide ${index + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == index ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
