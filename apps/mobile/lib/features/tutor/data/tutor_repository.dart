import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where part of an answer came from, e.g. "Unit06 Genetics", page 12.
class TutorSource {
  const TutorSource({required this.title, this.page});

  factory TutorSource.fromJson(Map<String, dynamic> json) => TutorSource(
    title: '${json['title'] ?? ''}',
    page: (json['page'] as num?)?.toInt(),
  );

  final String title;
  final int? page;

  String get label => page == null ? title : '$title, p. $page';
}

/// One answer from `POST /learn/ask`.
class TutorAnswer {
  const TutorAnswer({
    required this.answer,
    required this.grounded,
    this.sources = const [],
  });

  factory TutorAnswer.fromJson(Map<String, dynamic> json) => TutorAnswer(
    answer: '${json['answer'] ?? ''}',
    grounded: json['grounded'] == true,
    sources: [
      for (final s in (json['sources'] as List?) ?? const [])
        if (s is Map) TutorSource.fromJson(Map<String, dynamic>.from(s)),
    ],
  );

  final String answer;

  /// False = the approved books don't contain the answer.
  final bool grounded;
  final List<TutorSource> sources;
}

/// Ask BrAInBox. Only this layer calls the API.
abstract interface class TutorRepository {
  Future<TutorAnswer> ask(String question, {String? topicId});
}

class ApiTutorRepository implements TutorRepository {
  ApiTutorRepository(this.api);

  final ApiClient api;

  @override
  Future<TutorAnswer> ask(String question, {String? topicId}) async =>
      TutorAnswer.fromJson(
        await api.post<Map<String, dynamic>>(
          '/learn/ask',
          data: {'question': question, 'topic_id': ?topicId},
        ),
      );
}

/// DEBUG ONLY (`USE_FAKE_API=true`).
class FakeTutorRepository implements TutorRepository {
  @override
  Future<TutorAnswer> ask(String question, {String? topicId}) async =>
      const TutorAnswer(
        answer: 'This is a sample answer from the approved notes.',
        grounded: true,
        sources: [TutorSource(title: 'Sample notes', page: 1)],
      );
}

final tutorRepositoryProvider = Provider<TutorRepository>(
  (ref) => Env.useFakeApi
      ? FakeTutorRepository()
      : ApiTutorRepository(ref.watch(apiClientProvider)),
);
