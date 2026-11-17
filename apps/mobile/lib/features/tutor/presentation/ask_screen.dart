import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Ask BrAInBox (AI tutor chat), optionally about a topic.
///
/// Route: `/ask?topicId=...` (full screen).
///
/// Not built yet: this is an honest "coming soon" page with links to what
/// already works. No chat UI and no made-up answers until the tutor backend
/// exists.
class AskScreen extends StatelessWidget {
  const AskScreen({super.key, this.topicId});

  final String? topicId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topicId = this.topicId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask BrAInBox'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                header: true,
                child: Text(
                  'Coming soon',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Soon you'll be able to ask the AI tutor questions about the "
                "syllabus here. It isn't ready yet, so nothing you type would "
                'get a real answer.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (topicId != null) ...[
                AppButton(
                  label: 'Back to the topic',
                  icon: Icons.menu_book_outlined,
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.topicPath(topicId)),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Practise this topic',
                  icon: Icons.bolt,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(
                    AppRoutes.quizSetupPath(topicId: topicId, mode: 'quick'),
                  ),
                ),
              ] else ...[
                AppButton(
                  label: 'Browse topics',
                  icon: Icons.menu_book_outlined,
                  onPressed: () => context.go(AppRoutes.learn),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'See my next steps',
                  icon: Icons.route_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(AppRoutes.nextSteps),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
