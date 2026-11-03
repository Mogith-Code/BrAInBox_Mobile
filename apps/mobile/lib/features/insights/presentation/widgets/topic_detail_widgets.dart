import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/insights_models.dart';
import 'insights_ring.dart';
import 'insights_style.dart';
import 'status_chip.dart';

/// Header card on Topic detail: ring, name, unit, status, counts.
class TopicHeaderCard extends StatelessWidget {
  const TopicHeaderCard({
    super.key,
    required this.topic,
    required this.minQuestionsPerTopic,
  });

  final TopicResult topic;
  final int minQuestionsPerTopic;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = InsightsColors.mutedText(context);
    final subtitle = InsightsText.topicSubtitle(topic);
    final needed = topic.questionsNeeded(minQuestionsPerTopic);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            InsightsRing(
              percent: topic.percent,
              size: 88,
              strokeWidth: 9,
              faded: !topic.reliable,
              labelStyle: textTheme.titleLarge,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.topic, style: textTheme.titleLarge),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  StatusChip(status: topic.status),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${topic.correct} correct of ${topic.attempted} attempted',
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    '${topic.unanswered} unanswered',
                    style: textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  if (!topic.reliable && needed > 0)
                    Text(
                      InsightsText.needsMore(needed),
                      style: textTheme.bodySmall?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "What this means" / "What to revise next" from the feedback item.
class FeedbackTextCard extends StatelessWidget {
  const FeedbackTextCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(text, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A question to review, in the MistakeCard style: red accent bar, the
/// question, and an expandable model answer when the backend sends one.
class ReviewQuestionCard extends StatefulWidget {
  const ReviewQuestionCard({super.key, required this.question});

  final ReviewQuestion question;

  @override
  State<ReviewQuestionCard> createState() => _ReviewQuestionCardState();
}

class _ReviewQuestionCardState extends State<ReviewQuestionCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final answer = widget.question.modelAnswer;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: AppColors.error),
              Expanded(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.cancel_outlined,
                            color: AppColors.error,
                            semanticLabel: 'Answered wrong',
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              widget.question.question,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      if (answer != null && answer.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        TextButton.icon(
                          onPressed: () => setState(() => _open = !_open),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                          ),
                          icon: Icon(
                            _open
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                          ),
                          label: Text(
                            _open ? 'Hide model answer' : 'Show model answer',
                          ),
                        ),
                        if (_open)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: Text(answer, style: textTheme.bodyMedium),
                          ),
                      ],
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

/// A common misconception: title and optional description.
class MisconceptionTile extends StatelessWidget {
  const MisconceptionTile({super.key, required this.misconception});

  final Misconception misconception;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final description = misconception.description;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: InsightsColors.text(context),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(misconception.title, style: textTheme.titleSmall),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: InsightsColors.mutedText(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A study resource. Tapping it opens the link outside the app.
class ResourceCard extends StatelessWidget {
  const ResourceCard({super.key, required this.resource});

  final StudyResource resource;

  static IconData iconFor(ResourceType type) => switch (type) {
    ResourceType.video => Icons.play_circle_outline_rounded,
    ResourceType.article => Icons.article_outlined,
    ResourceType.pdf => Icons.picture_as_pdf_outlined,
    ResourceType.notes => Icons.sticky_note_2_outlined,
    ResourceType.website => Icons.language_rounded,
    ResourceType.unknown => Icons.link_rounded,
  };

  static String labelFor(ResourceType type) => switch (type) {
    ResourceType.video => 'Video',
    ResourceType.article => 'Article',
    ResourceType.pdf => 'PDF',
    ResourceType.notes => 'Notes',
    ResourceType.website => 'Website',
    ResourceType.unknown => 'Link',
  };

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri.tryParse(resource.url);
    var opened = false;
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } on Object {
        opened = false;
      }
    }
    if (!opened) {
      messenger?.showSnackBar(
        const SnackBar(content: Text("Couldn't open this link.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final host = Uri.tryParse(resource.url)?.host ?? '';
    final type = labelFor(resource.resourceType);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        link: true,
        label: '$type: ${resource.title}',
        excludeSemantics: true,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(context),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      iconFor(resource.resourceType),
                      color: InsightsColors.infoAccent(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resource.title, style: textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          host.isEmpty ? type : '$type · $host',
                          style: textTheme.bodySmall?.copyWith(
                            color: InsightsColors.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 20,
                    color: InsightsColors.mutedText(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
