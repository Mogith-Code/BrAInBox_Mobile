import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/exams_controller.dart';
import '../domain/exams_models.dart';

/// Generate model paper screen - Configure and generate customized A/L Biology model papers.
///
/// Route: `/exams/generate`
class GeneratePaperScreen extends ConsumerStatefulWidget {
  const GeneratePaperScreen({super.key, this.initialUnits = const []});

  final List<int> initialUnits;

  @override
  ConsumerState<GeneratePaperScreen> createState() => _GeneratePaperScreenState();
}

class _GeneratePaperScreenState extends ConsumerState<GeneratePaperScreen> {
  late final Set<int> _units = Set<int>.of(widget.initialUnits);
  int _count = 10;
  bool _loading = false;
  String? _error;

  void _toggle(int unit) {
    setState(() {
      if (!_units.remove(unit)) {
        _units.add(unit);
      }
    });
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final units = _units.toList()..sort();
      final paper = await ref
          .read(examSessionControllerProvider.notifier)
          .generatePaper(units: units, count: _count);

      if (!mounted) return;
      setState(() => _loading = false);
      context.push(AppRoutes.examAttemptPath(paper.paperId));
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('Failed to fetch') ||
          msg.contains('Connection refused') ||
          msg.contains('SocketException') ||
          msg.contains('connectTimeout')) {
        msg =
            'Cannot connect to backend (${Env.apiBaseUrl}). Please make sure the backend server is running.';
      }
      setState(() {
        _loading = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(examSessionControllerProvider);
    final selected = _units.length;
    final enough = _count >= selected;
    final perUnit = selected == 0 ? 0 : (_count / selected).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create practice paper'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Select the units you want to practise. Questions are generated and grounded in the approved A/L Biology resource books.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'Units ($selected/10 selected)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _units.addAll(kBiologyUnits.keys)),
                child: const Text('Select all'),
              ),
              TextButton(
                onPressed: _loading ? null : () => setState(_units.clear),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final entry in kBiologyUnits.entries)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: _units.contains(entry.key)
                      ? AppColors.primary
                      : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              color: _units.contains(entry.key)
                  ? AppColors.primarySoft
                  : AppColors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: _units.contains(entry.key),
                activeColor: AppColors.primary,
                onChanged: _loading ? null : (_) => _toggle(entry.key),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Unit ${entry.key}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  entry.value,
                  style: TextStyle(
                    color: _units.contains(entry.key)
                        ? AppColors.ink
                        : AppColors.muted,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Number of questions: $_count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Slider(
            value: _count.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            activeColor: AppColors.primary,
            label: '$_count',
            onChanged:
                _loading ? null : (v) => setState(() => _count = v.round()),
          ),
          if (selected > 0 && enough)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'About $perUnit question(s) per unit.',
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          if (selected > 0 && !enough)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Increase the number of questions (at least one per selected unit).',
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.errorDark),
                    ),
                  ),
                ],
              ),
            ),
          AppButton(
            label: _loading
                ? 'Generating paper... this may take up to a minute'
                : 'Generate paper',
            isLoading: _loading,
            onPressed:
                (selected == 0 || !enough || _loading) ? null : _start,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
