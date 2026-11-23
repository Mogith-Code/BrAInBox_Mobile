import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../data/tutor_repository.dart';

/// Ask BrAInBox (AI tutor chat), optionally about a topic.
///
/// Route: `/ask?topicId=...` (full screen). Answers come only from the
/// approved books and show their sources. The chat is kept in memory.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key, this.topicId});

  final String? topicId;

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

/// One bubble: the student's question or the tutor's answer.
class _Message {
  const _Message.student(this.text) : answer = null, isError = false;
  _Message.tutor(TutorAnswer this.answer)
    : text = answer.answer,
      isError = false;
  const _Message.error(this.text) : answer = null, isError = true;

  final String text;
  final TutorAnswer? answer;
  final bool isError;

  bool get fromStudent => answer == null && !isError;
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Message>[];
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.length < 3 || _sending) return;
    setState(() {
      _messages.add(_Message.student(question));
      _sending = true;
      _input.clear();
    });
    _scrollToEnd();
    _Message reply;
    try {
      final answer = await ref
          .read(tutorRepositoryProvider)
          .ask(question, topicId: widget.topicId);
      reply = _Message.tutor(answer);
    } catch (e) {
      reply = _Message.error(ErrorMessages.of(e));
    }
    if (!mounted) return;
    setState(() {
      _messages.add(reply);
      _sending = false;
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          widget.topicId == null
                              ? 'Ask any A/L Biology question. Answers come '
                                    'from the approved notes.'
                              : 'Ask a question about this topic. Answers '
                                    'come from the approved notes.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, index) => index == _messages.length
                          ? const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _Bubble(message: _messages[index]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type your question',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sources = message.answer?.sources ?? const <TutorSource>[];
    return Align(
      alignment: message.fromStudent
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: message.fromStudent
              ? AppColors.primarySoft
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.text,
              style: message.isError
                  ? textTheme.bodyMedium?.copyWith(color: AppColors.error)
                  : textTheme.bodyMedium,
            ),
            if (sources.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sources: ${sources.map((s) => s.label).join('; ')}',
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
