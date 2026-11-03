import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter_test/flutter_test.dart';

String _message(String code, {int? retryAfter}) => ErrorMessages.of(
  ApiException(code: code, message: 'raw', retryAfter: retryAfter),
);

void main() {
  test('visual and AI job codes get friendly text', () {
    expect(_message('VISUAL_NOT_FOUND'), "This visual isn't available.");
    expect(_message('TOPIC_NOT_FOUND'), "We couldn't find this topic.");
    expect(
      _message('JOB_NOT_FOUND'),
      'We lost track of this request. Please try again.',
    );
    expect(
      _message('ALREADY_REPORTED'),
      'You already reported this visual. An admin will check it soon.',
    );
    expect(_message('NOT_BIOLOGY'), 'I can only draw Biology visuals.');
    expect(
      _message('AI_DAILY_LIMIT'),
      "Today's free AI requests are used up. Please try again tomorrow.",
    );
    expect(
      _message('AI_SERVICE_UNAVAILABLE'),
      'The AI is busy right now. Please try again in a few minutes.',
    );
    expect(_message('FILE_NOT_FOUND'), "This picture couldn't be loaded.");
  });

  test('VISUAL_LIMIT_REACHED tells how long to wait', () {
    expect(
      _message('VISUAL_LIMIT_REACHED', retryAfter: 86400),
      "You've made today's visuals. Try again in 24 hours.",
    );
    expect(
      _message('VISUAL_LIMIT_REACHED', retryAfter: 5400),
      "You've made today's visuals. Try again in 1 hour 30 minutes.",
    );
    expect(
      _message('VISUAL_LIMIT_REACHED', retryAfter: 300),
      "You've made today's visuals. Try again in 5 minutes.",
    );
    expect(
      _message('VISUAL_LIMIT_REACHED'),
      "You've made today's visuals. Try again tomorrow.",
    );
  });
}
