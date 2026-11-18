import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/exams_controller.dart';
import '../domain/exams_models.dart';
import '../domain/paper_models.dart';

/// Model paper generator: units + MCQ / structured / essay mix.
/// `POST /papers/generate` returns 202 + a job, polled with JobPoller.
///
/// Route: `/exams/generate`
class GeneratePaperScreen extends ConsumerStatefulWidget {
  const GeneratePaperScreen({super.key, this.initialUnits = const []});

  final List<int> initialUnits;

  @override
  ConsumerState<GeneratePaperScreen> createState() =>
      _GeneratePaperScreenState();
}

class _GeneratePaperScreenState extends ConsumerState<GeneratePaperScreen> {
  late final Set<int> _units = Set<int>.of(widget.initialUnits);
  int _mcq = 20;
  int _structured = 0;
  int _essay = 0;
  int? _minutes = 60;

  bool get _valid => _units.isNotEmpty && (_mcq + _structured + _essay) > 0;

  Future<void> _start() async {
    final id = await ref
        .read(generatePaperControllerProvider.notifier)
        .generate(
          PaperBlueprint(
            unitNumbers: _units.toList()..sort(),
            mcqCount: _mcq,
            structuredCount: _structured,
            essayCount: _essay,
            timeLimitMinutes: _minutes,
          ),
        );
    if (id != null && mounted) {
      context.pushReplacement(AppRoutes.examAttemptPath(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gen = ref.watch(generatePaperControllerProvider);

    if (gen.running) {
      return Scaffold(
        appBar: AppBar(title: const Text('Generate model paper')),
        body: Center(
          child: AiGeneratingLoader(
            message: 'Building your model paper...',
            progress: (gen.progress ?? 0) > 0 ? gen.progress : null,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Generate model paper')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (gen.error != null) ...[
            ErrorBanner(message: gen.error!, onRetry: _valid ? _start : null),
            const SizedBox(height: AppSpacing.md),
          ],
          const _Heading('Units'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final e in kBiologyUnits.entries)
                FilterChip(
                  label: Text('Unit ${e.key} · ${e.value}'),
                  selected: _units.contains(e.key),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (on) => setState(
                    () => on ? _units.add(e.key) : _units.remove(e.key),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Heading('Questions'),
          _Counter(
            label: 'Part I · MCQ',
            value: _mcq,
            max: 60,
            step: 5,
            onChanged: (v) => setState(() => _mcq = v),
          ),
          _Counter(
            label: 'Part II · Structured',
            value: _structured,
            max: 10,
            onChanged: (v) => setState(() => _structured = v),
          ),
          _Counter(
            label: 'Essay',
            value: _essay,
            max: 6,
            onChanged: (v) => setState(() => _essay = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Heading('Time limit'),
          DropdownButtonFormField<int?>(
            initialValue: _minutes,
            items: const [
              DropdownMenuItem(child: Text('No time limit')),
              DropdownMenuItem(value: 30, child: Text('30 minutes')),
              DropdownMenuItem(value: 60, child: Text('1 hour')),
              DropdownMenuItem(value: 120, child: Text('2 hours')),
              DropdownMenuItem(value: 180, child: Text('3 hours')),
            ],
            onChanged: (v) => setState(() => _minutes = v),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Generate paper',
            icon: Icons.auto_awesome,
            onPressed: _valid ? _start : null,
          ),
          if (_units.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Choose at least one unit.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
    ),
  );
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      IconButton(
        tooltip: 'Fewer $label',
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: value > 0
            ? () => onChanged((value - step).clamp(0, max))
            : null,
      ),
      SizedBox(
        width: 32,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      IconButton(
        tooltip: 'More $label',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: value < max
            ? () => onChanged((value + step).clamp(0, max))
            : null,
      ),
    ],
  );
}
