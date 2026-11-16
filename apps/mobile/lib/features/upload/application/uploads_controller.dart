import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../notes/application/library_controller.dart';
import '../../syllabus/data/learn_repository.dart';

part 'uploads_controller.g.dart';

/// "My uploaded notes": every upload, newest first, plus the ones being
/// sent right now.
///
/// [startUpload] adds a local item with a progress bar, sends the file,
/// then polls `GET /uploads/{id}` until it is `done` or `failed`. Kept
/// alive so uploads finish while the student uses other screens.
@Riverpod(keepAlive: true)
class UploadsController extends _$UploadsController {
  /// Stop polling one upload after this many tries.
  static const maxPolls = 150;

  final Set<String> _polling = {};
  int _localIds = 0;

  @override
  Future<List<Upload>> build() async {
    final uploads = await ref.watch(learnRepositoryProvider).fetchUploads();
    for (final u in uploads) {
      if (u.status.isBusy) _poll(u.id);
    }
    return uploads;
  }

  Future<void> refresh() async {
    final local = _items.where((u) => u.id.startsWith('local-')).toList();
    ref.invalidateSelf();
    try {
      final fresh = await future;
      if (ref.mounted && local.isNotEmpty) {
        state = AsyncData([...local, ...fresh]);
      }
    } catch (_) {
      // The screen shows the error.
    }
  }

  List<Upload> get _items => state.value ?? const [];

  void _put(Upload upload, {String? replacing}) {
    final id = replacing ?? upload.id;
    final items = _items;
    final i = items.indexWhere((u) => u.id == id);
    state = AsyncData(i < 0 ? [upload, ...items] : ([...items]..[i] = upload));
  }

  /// Sends [file] and returns the server's upload id (null if sending
  /// failed; the item then shows "Failed").
  Future<String?> startUpload(
    PickedUploadFile file, {
    String? topicId,
    String? topicTitle,
    SummaryLength summaryLength = SummaryLength.medium,
  }) async {
    final localId = 'local-${++_localIds}';
    var local = Upload(
      id: localId,
      fileName: file.name,
      status: UploadStatus.uploading,
      createdAt: DateTime.now(),
      topic: topicId == null
          ? null
          : UploadTopic(id: topicId, title: topicTitle ?? ''),
    );
    _put(local);
    try {
      final created = await ref
          .read(learnRepositoryProvider)
          .createUpload(
            file,
            topicId: topicId,
            summaryLength: summaryLength,
            onProgress: (p) {
              if (!ref.mounted) return;
              local = local.copyWith(sendProgress: p);
              _put(local);
            },
          );
      if (!ref.mounted) return null;
      _put(
        created.copyWith(
          fileName: created.fileName.isEmpty ? file.name : created.fileName,
          createdAt: created.createdAt ?? local.createdAt,
          topic: created.topic ?? local.topic,
          status: created.status == UploadStatus.uploading
              ? UploadStatus.processing
              : created.status,
        ),
        replacing: localId,
      );
      if (created.status != UploadStatus.done) _poll(created.id);
      return created.id;
    } catch (error) {
      if (ref.mounted) {
        _put(
          local.copyWith(
            status: UploadStatus.failed,
            error: ErrorMessages.of(error),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _poll(String id) async {
    if (!_polling.add(id)) return;
    final repository = ref.read(learnRepositoryProvider);
    final interval = ref.read(learnPollIntervalProvider);
    try {
      for (var i = 0; i < maxPolls; i++) {
        await Future<void>.delayed(interval);
        if (!ref.mounted) return;
        final Upload upload;
        try {
          upload = await repository.fetchUpload(id);
        } catch (_) {
          continue; // offline for a moment: try again next time
        }
        if (!ref.mounted) return;
        if (!_items.any((u) => u.id == id)) return; // deleted meanwhile
        _put(upload);
        if (!upload.status.isBusy) return;
      }
    } finally {
      _polling.remove(id);
    }
  }

  /// Deletes an upload straight away; puts it back if the call fails.
  Future<void> delete(String id) async {
    final before = _items;
    state = AsyncData([
      for (final u in before)
        if (u.id != id) u,
    ]);
    if (id.startsWith('local-')) return; // never reached the server
    try {
      await ref.read(learnRepositoryProvider).deleteUpload(id);
      if (ref.mounted) ref.invalidate(bookmarksControllerProvider);
    } catch (_) {
      if (ref.mounted) state = AsyncData(before);
      rethrow;
    }
  }

  /// Saves the upload's summary as one of the student's short notes.
  Future<void> saveToShortNotes(String id) async {
    await ref.read(learnRepositoryProvider).saveUploadToShortNotes(id);
    if (ref.mounted) ref.invalidate(bookmarksControllerProvider);
  }
}

/// The status of one upload in the list. Only notifies when it changes.
@riverpod
UploadStatus? uploadStatus(Ref ref, String uploadId) => ref
    .watch(uploadsControllerProvider)
    .value
    ?.where((u) => u.id == uploadId)
    .firstOrNull
    ?.status;

/// One upload with its summary, key points and text. Reloads by itself
/// when the upload's status changes in the list.
@riverpod
Future<Upload> uploadDetail(Ref ref, String uploadId) {
  ref.watch(uploadStatusProvider(uploadId));
  return ref.read(learnRepositoryProvider).fetchUpload(uploadId);
}
