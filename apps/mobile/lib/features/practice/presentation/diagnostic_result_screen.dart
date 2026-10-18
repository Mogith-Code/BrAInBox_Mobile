import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/diagnostic_controller.dart';
import '../domain/diagnostic_models.dart';

/// "Your starting point" (Figma A13): strongest / needs-work cards,
/// mastery by unit, the formative-feedback note and "See my learning plan".
///
/// Route: `/diagnostic/result`.
class DiagnosticResultScreen extends ConsumerWidget {
  const DiagnosticResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(diagnosticResultProvider);

    return Scaffold(
      body: SafeArea(
        child: result.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: ErrorBanner(
              message: ErrorMessages.of(error),
              onRetry: () => ref.invalidate(diagnosticResultProvider),
            ),
          ),
          data: (r) => _ResultBody(result: r),
        ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});

  final DiagnosticResult result;

  static MasteryStatus _status(UnitStatus s) => switch (s) {
    UnitStatus.strong => MasteryStatus.strong,
    UnitStatus.ok => MasteryStatus.ok,
    UnitStatus.needsWork => MasteryStatus.needsWork,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strongest = result.strongest;
    final needsWork = result.needsWork;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Your starting point',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (strongest != null)
                        Expanded(
                          child: _HighlightCard(
                            icon: Icons.eco_outlined,
                            label: 'Your strongest',
                            unit: strongest,
                            background: AppColors.successSoft,
                            accent: AppColors.successDark,
                          ),
                        ),
                      if (strongest != null && needsWork != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (needsWork != null)
                        Expanded(
                          child: _HighlightCard(
                            icon: Icons.warning_amber_rounded,
                            label: 'Needs work',
                            unit: needsWork,
                            background: AppColors.warningSoft,
                            accent: AppColors.warningDark,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Mastery by unit',
                              style: textTheme.titleSmall?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (result.summaryAiGenerated) const AiBadge(),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final (i, unit) in result.units.indexed)
                        UnitMasteryRow(
                          index: i + 1,
                          title: unit.unitTitle,
                          mastery: unit.fraction,
                          status: _status(unit.status),
                          // Figma: only the strongest / needs-work unit is bold.
                          emphasised:
                              unit.unitCode == strongest?.unitCode ||
                              unit.unitCode == needsWork?.unitCode,
                        ),
                      if (result.summary.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          result.summary,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _Disclaimer(text: result.disclaimer),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: AppButton(
            label: 'See my learning plan',
            trailingIcon: Icons.arrow_forward,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.label,
    required this.unit,
    required this.background,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final UnitRef unit;
  final Color background;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: ${unit.unitLabel}, ${unit.unitTitle}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: accent),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      style: textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                unit.unitLabel,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unit.unitTitle,
                style: textTheme.bodyMedium?.copyWith(color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "ⓘ **Formative feedback** — not an official exam mark."
class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.ink);
    final dash = text.indexOf(' — ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              dash < 0
                  ? TextSpan(text: text, style: style)
                  : TextSpan(
                      style: style,
                      children: [
                        TextSpan(
                          text: text.substring(0, dash),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: text.substring(dash)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
