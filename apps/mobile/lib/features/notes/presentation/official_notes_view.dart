import 'dart:typed_data';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../syllabus/data/learn_repository.dart';
import '../../syllabus/presentation/widgets/learn_widgets.dart';
import '../application/notes_controller.dart';

/// Sent up the widget tree while the student pinches or is zoomed in, so the
/// Topic screen stops side-swipes from changing tab during the gesture.
class NotesZoomNotification extends Notification {
  const NotesZoomNotification({required this.active});

  final bool active;
}

/// The Government notes: the real uploaded book pages for this topic.
class OfficialNotesView extends ConsumerWidget {
  const OfficialNotesView({
    super.key,
    required this.detail,
    required this.onOpenAiNotes,
  });

  final TopicDetail detail;

  /// Switches the Notes tab to AI notes (used when there is no book yet).
  final VoidCallback onOpenAiNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = officialNotesProvider(detail.topic.id);
    return switch (ref.watch(provider)) {
      AsyncValue(:final value?) when _hasPages(value) => _BookReader(
        notes: value,
        topicId: detail.topic.id,
      ),
      AsyncValue(hasValue: true) => LearnEmptyState(
        icon: Icons.menu_book_outlined,
        title: "Government notes aren't available for this topic yet",
        message: 'You can read the AI notes in the meantime.',
        action: GradientButton(
          label: 'Open AI notes',
          expand: false,
          onPressed: onOpenAiNotes,
        ),
      ),
      AsyncError(:final error) => ErrorCard(
        error: error,
        onRetry: () => ref.invalidate(provider),
      ),
      _ => const SkeletonList(label: 'Loading government notes'),
    };
  }

  static bool _hasPages(OfficialNotes notes) =>
      notes.available && notes.books.any((book) => book.pageCount > 0);
}

/// The book picker (when there are several books) and the page list.
class _BookReader extends ConsumerStatefulWidget {
  const _BookReader({required this.notes, required this.topicId});

  final OfficialNotes notes;
  final String topicId;

  @override
  ConsumerState<_BookReader> createState() => _BookReaderState();
}

class _BookReaderState extends ConsumerState<_BookReader> {
  final _stopwatch = Stopwatch()..start();
  late final LearnRepository _repository = ref.read(learnRepositoryProvider);
  late final List<OfficialBook> _books = [
    for (final book in widget.notes.books)
      if (book.pageCount > 0) book,
  ];
  late OfficialBook _book = _books.firstWhere(
    (book) => book.documentId == widget.notes.openDocumentId,
    orElse: () => _books.first,
  );
  bool _sentCompleted = false;

  /// The page the API asked us to open, only for the book it belongs to.
  int get _firstPage => _book.documentId == widget.notes.openDocumentId
      ? widget.notes.openPage.clamp(1, _book.pageCount)
      : 1;

  void _onReachedLastPage() {
    if (_sentCompleted) return;
    _sentCompleted = true;
    _sendProgress(completed: true);
  }

  void _sendProgress({required bool completed}) {
    _repository
        .sendProgress(
          widget.topicId,
          ProgressEvent.read,
          seconds: _stopwatch.elapsed.inSeconds,
          completed: completed,
        )
        .catchError((Object _) {}); // best effort
  }

  @override
  void dispose() {
    // Same rule as the AI notes: a short visit isn't counted as reading.
    if (!_sentCompleted && _stopwatch.elapsed.inSeconds >= 3) {
      _sendProgress(completed: false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_books.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: DropdownButton<OfficialBook>(
              value: _book,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                for (final book in _books)
                  DropdownMenuItem(
                    value: book,
                    child: Text(book.title, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (book) {
                if (book == null || book == _book) return;
                // The old list may have been zoomed: free the tab swipe.
                const NotesZoomNotification(active: false).dispatch(context);
                setState(() => _book = book);
              },
            ),
          ),
        if (!widget.notes.exactMatch)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              'Showing this unit from the start.',
              style: textTheme.bodySmall?.copyWith(color: context.learnMuted),
            ),
          ),
        Expanded(
          child: _PageList(
            // A new book starts with a fresh scroll position and zoom.
            key: ValueKey(_book.documentId),
            book: _book,
            firstPage: _firstPage,
            onReachedLastPage: _onReachedLastPage,
          ),
        ),
      ],
    );
  }
}

/// A lazy vertical list of pages with pinch zoom and "Page X of Y".
class _PageList extends StatefulWidget {
  const _PageList({
    super.key,
    required this.book,
    required this.firstPage,
    required this.onReachedLastPage,
  });

  final OfficialBook book;
  final int firstPage;
  final VoidCallback onReachedLastPage;

  @override
  State<_PageList> createState() => _PageListState();
}

class _PageListState extends State<_PageList> {
  /// Height / width of an A4 page. Every slot has this shape, so we can jump
  /// straight to a page without loading the ones before it.
  static const _pageRatio = 1.414;
  static const _pageGap = AppSpacing.sm;

  final _zoom = TransformationController();
  ScrollController? _scroll;
  double _slotHeight = 0;
  late int _page = widget.firstPage;
  int _fingers = 0;
  bool _zoomed = false;

  /// The list must not scroll during a pinch or while zoomed in.
  bool get _locked => _fingers >= 2 || _zoomed;

  /// Creates the scroll position once the page size is known, and keeps the
  /// same page in view if the size changes (e.g. the phone is rotated).
  void _prepareScroll(double width) {
    final slotHeight = width * _pageRatio + _pageGap;
    if (slotHeight == _slotHeight) return;
    _slotHeight = slotHeight;
    final offset = (_page - 1) * slotHeight;

    final scroll = _scroll;
    if (scroll == null) {
      _scroll = ScrollController(initialScrollOffset: offset)
        ..addListener(_updatePage);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updatePage());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients) scroll.jumpTo(offset);
      });
    }
  }

  /// Works out which page is in the middle of the screen.
  void _updatePage() {
    final scroll = _scroll;
    if (!mounted || scroll == null || !scroll.hasClients) return;
    final position = scroll.position;
    final middle = position.pixels + position.viewportDimension / 2;
    final atEnd = position.pixels >= position.maxScrollExtent - 1;
    final page = atEnd
        ? widget.book.pageCount
        : (middle / _slotHeight).floor().clamp(0, widget.book.pageCount - 1) +
              1;
    if (page != _page) setState(() => _page = page);
    if (page == widget.book.pageCount) widget.onReachedLastPage();
  }

  void _setFingers(int fingers) {
    final wasLocked = _locked;
    setState(() => _fingers = fingers < 0 ? 0 : fingers);
    if (wasLocked != _locked) _reportLock();
  }

  void _onZoomEnd() {
    final wasLocked = _locked;
    setState(() => _zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01);
    if (wasLocked != _locked) _reportLock();
  }

  void _resetZoom() {
    _zoom.value = Matrix4.identity();
    _onZoomEnd();
  }

  void _reportLock() =>
      NotesZoomNotification(active: _locked).dispatch(context);

  @override
  void dispose() {
    _scroll?.dispose();
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _prepareScroll(constraints.maxWidth);
              return Listener(
                onPointerDown: (_) => _setFingers(_fingers + 1),
                onPointerUp: (_) => _setFingers(_fingers - 1),
                onPointerCancel: (_) => _setFingers(_fingers - 1),
                child: InteractiveViewer(
                  transformationController: _zoom,
                  minScale: 1,
                  maxScale: 4,
                  panEnabled: _zoomed,
                  onInteractionEnd: (_) => _onZoomEnd(),
                  child: ListView.builder(
                    controller: _scroll,
                    physics: _locked
                        ? const NeverScrollableScrollPhysics()
                        : const ClampingScrollPhysics(),
                    // Build only the pages on screen, so only those load.
                    scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                    itemExtent: _slotHeight,
                    itemCount: book.pageCount,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: _pageGap),
                      child: _BookPage(
                        key: ValueKey('${book.documentId}/${index + 1}'),
                        documentId: book.documentId,
                        page: index + 1,
                        pageCount: book.pageCount,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Page $_page of ${book.pageCount}',
                style: textTheme.labelMedium?.copyWith(
                  color: context.learnMuted,
                ),
              ),
              if (_zoomed)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetZoom,
                    child: const Text('Reset zoom'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One page: a placeholder while loading, Retry if it fails.
class _BookPage extends ConsumerStatefulWidget {
  const _BookPage({
    super.key,
    required this.documentId,
    required this.page,
    required this.pageCount,
  });

  final String documentId;
  final int page;
  final int pageCount;

  @override
  ConsumerState<_BookPage> createState() => _BookPageState();
}

class _BookPageState extends ConsumerState<_BookPage> {
  late Future<Uint8List> _bytes = _load();

  Future<Uint8List> _load() =>
      ref.read(officialPageCacheProvider).load(widget.documentId, widget.page);

  @override
  Widget build(BuildContext context) {
    final label = 'Page ${widget.page} of ${widget.pageCount}';
    return FutureBuilder<Uint8List>(
      future: _bytes,
      // A page already in memory shows at once, with no placeholder flash.
      initialData: ref
          .read(officialPageCacheProvider)
          .peek(widget.documentId, widget.page),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Couldn't load page ${widget.page}."),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _bytes = _load();
                  }),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return Semantics(
            label: 'Loading page ${widget.page}',
            child: const ExcludeSemantics(
              child: SkeletonBox(height: double.infinity),
            ),
          );
        }
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          semanticLabel: label,
          // Keeps memory low: no need to decode wider than the screen.
          cacheWidth:
              (MediaQuery.sizeOf(context).width *
                      MediaQuery.devicePixelRatioOf(context) *
                      2)
                  .round(),
          gaplessPlayback: true,
        );
      },
    );
  }
}
