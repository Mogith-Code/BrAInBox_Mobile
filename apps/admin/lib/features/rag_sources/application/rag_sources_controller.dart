import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/admin_errors.dart';

import '../data/rag_sources_repository.dart';
import '../domain/rag_sources_models.dart';

/// The sources table, upload and re-index.
///
/// Upload and re-index return right away (the backend answers 202 with a
/// job). The list is reloaded then, and again when the job has finished, so
/// the status moves from "Waiting" to "Ready" / "Failed" by itself.
///
/// Every action returns an error sentence (for a snack bar) or null.
class RagSourcesController extends AsyncNotifier<List<RagSource>> {
  RagSourcesRepository get _repository =>
      ref.read(ragSourcesRepositoryProvider);

  @override
  Future<List<RagSource>> build() =>
      ref.watch(ragSourcesRepositoryProvider).sources();

  Future<String?> upload(
    RagUpload form, {
    required String fileName,
    required List<int> bytes,
  }) => _run(() => _repository.upload(form, fileName: fileName, bytes: bytes));

  /// Re-index one document, or every document when [documentId] is null.
  Future<String?> reindex({String? documentId}) =>
      _run(() => _repository.reindex(documentId: documentId));

  Future<String?> _run(Future<RagJob> Function() start) async {
    try {
      final job = await start();
      await _reload();
      unawaited(_follow(job.jobId));
      return null;
    } catch (e) {
      return adminErrorMessage(e);
    }
  }

  /// Reloads once the job is done. A failed job shows up as a "Failed" row,
  /// so errors here are not reported again.
  Future<void> _follow(String jobId) async {
    try {
      await _repository.waitForJob(jobId);
    } catch (_) {
      // Timed out or lost connection: the next reload shows the status.
    }
    await _reload();
  }

  Future<void> _reload() async {
    if (!ref.mounted) return;
    try {
      final rows = await _repository.sources();
      if (ref.mounted) state = AsyncData(rows);
    } catch (_) {
      // Keep the rows we have; Refresh can try again.
    }
  }
}

final ragSourcesProvider =
    AsyncNotifierProvider.autoDispose<RagSourcesController, List<RagSource>>(
      RagSourcesController.new,
    );
