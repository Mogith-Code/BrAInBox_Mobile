import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../application/profile_setup_controller.dart';
import '../../domain/profile_models.dart';

/// Small bold label above a group ("Stream", "Subject", "Days"...).
class SetupLabel extends StatelessWidget {
  const SetupLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ step 1 (A9)

/// "What are you studying?" - stream + subject.
class StreamStep extends StatelessWidget {
  const StreamStep({
    super.key,
    required this.state,
    required this.onStream,
    required this.onSubject,
  });

  final ProfileSetupState state;
  final ValueChanged<String> onStream;
  final ValueChanged<SubjectOption> onSubject;

  static IconData iconFor(String subjectId) => switch (subjectId) {
    'biology' => Icons.eco_outlined,
    'chemistry' => Icons.science_outlined,
    'physics' => Icons.track_changes,
    _ => Icons.menu_book_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final available = state.options.subjects.where((s) => s.available);
    final comingSoon = state.options.subjects.where((s) => !s.available);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenHeading(
          title: 'What are you studying?',
          subtitle: "We'll tailor every note and question to your syllabus.",
        ),
        const SetupLabel('Stream'),
        for (final stream in state.options.streams) ...[
          SelectableCard(
            selected: state.stream == stream.id,
            onTap: () => onStream(stream.id),
            semanticLabel: stream.name,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 2,
            ),
            child: Row(
              children: [
                const Icon(Icons.biotech_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    stream.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  state.stream == stream.id
                      ? Icons.check_circle_outline
                      : Icons.circle_outlined,
                  color: state.stream == stream.id
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SetupLabel('Subject'),
        for (final subject in available) ...[
          SelectableCard(
            selected: state.subject == subject.id,
            selectedColor: AppColors.white,
            onTap: () => onSubject(subject),
            semanticLabel: [
              subject.name,
              if (subject.units != null) '${subject.units} units',
              ?subject.syllabus,
            ].join(', '),
            child: Row(
              children: [
                IconTile(
                  icon: iconFor(subject.id),
                  size: 56,
                  color: AppColors.successDark,
                  background: AppColors.successSoft,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        [
                          if (subject.units != null) '${subject.units} units',
                          ?subject.syllabus,
                        ].join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.subject == subject.id)
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.check, size: 18, color: AppColors.white),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (comingSoon.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, subject) in comingSoon.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SelectableCard(
                    selected: false,
                    enabled: false,
                    semanticLabel: '${subject.name}, coming soon',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(iconFor(subject.id), color: AppColors.muted),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          subject.name,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const ComingSoonChip(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

// ------------------------------------------------------------ step 2 (A10)

/// "Set your goal" - exam year, target grade, confidence.
class GoalStep extends StatelessWidget {
  const GoalStep({
    super.key,
    required this.state,
    required this.onYear,
    required this.onGrade,
    required this.onConfidence,
  });

  final ProfileSetupState state;
  final ValueChanged<int> onYear;
  final ValueChanged<String> onGrade;
  final ValueChanged<int> onConfidence;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subjectName =
        state.options.subjects
            .where((s) => s.id == state.subject)
            .map((s) => s.name)
            .firstOrNull ??
        'Biology';
    final years = state.options.examYears;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenHeading(
          title: 'Set your goal',
          subtitle:
              'Honest answers = a better plan. You can change these '
              'anytime.',
        ),
        const SetupLabel('A/L exam year'),
        if (years.isNotEmpty)
          ExamYearPicker(
            years: years,
            value: state.examYear ?? years.first,
            onChanged: onYear,
          ),
        const SetupLabel('Target grade'),
        PillSelector<String>(
          options: [for (final g in state.options.targetGrades) g.id],
          value: state.targetGrade,
          labelOf: (id) =>
              state.options.targetGrades.firstWhere((g) => g.id == id).name,
          semanticPrefix: 'Target grade',
          onChanged: onGrade,
        ),
        SetupLabel('How confident do you feel in $subjectName?'),
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                confidenceLabel(state.confidence),
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.secondaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              LabeledSlider(
                value: state.confidence.toDouble(),
                min: 0,
                max: 100,
                minLabel: 'Not at all',
                maxLabel: 'Very',
                semanticFormatter: (v) => confidenceLabel(v.round()),
                onChanged: (v) => onConfidence(v.round()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ step 3 (A11)

/// "When can you study?" - days, hours per day, preferred time.
class AvailabilityStep extends StatelessWidget {
  const AvailabilityStep({
    super.key,
    required this.state,
    required this.onDays,
    required this.onHours,
    required this.onTime,
  });

  final ProfileSetupState state;
  final ValueChanged<Set<String>> onDays;
  final ValueChanged<double> onHours;
  final ValueChanged<String> onTime;

  static String hoursText(double h) =>
      h % 1 == 0 ? '${h.toStringAsFixed(0)}h' : '${h.toStringAsFixed(1)}h';

  static String emojiFor(String id) => switch (id) {
    'morning' => '☀️',
    'evening' => '🌇',
    'night' => '🌙',
    _ => '🕒',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenHeading(
          title: 'When can you study?',
          subtitle:
              "We'll pace your plan so it fits real life — tuition "
              'included.',
        ),
        const SetupLabel('Days'),
        DayChips(selected: state.studyDays, onChanged: onDays),
        SetupLabel(
          'Hours per day',
          trailing: Text(
            hoursText(state.hoursPerDay),
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        LabeledSlider(
          value: state.hoursPerDay,
          min: 1,
          max: 6,
          divisions: 10, // half-hour steps
          minLabel: '1h',
          maxLabel: '6h',
          semanticFormatter: (v) => '${hoursText(v)} per day',
          onChanged: onHours,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.studyDays.isNotEmpty)
          Text(
            weeklyHoursHint(state.weeklyHours),
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryDark,
            ),
          ),
        const SetupLabel('Preferred time'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, time) in state.options.preferredTimes.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SelectableCard(
                  selected: state.preferredTime == time.id,
                  onTap: () => onTime(time.id),
                  semanticLabel: '${time.label}, ${time.hint}',
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emojiFor(time.id),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        time.label,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        time.hint,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
