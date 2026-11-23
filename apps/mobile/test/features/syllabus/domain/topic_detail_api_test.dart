import 'package:brainbox_mobile/features/syllabus/domain/syllabus_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the topic response the backend really sends', () {
    final detail = TopicDetail.fromApi({
      'id': 't1',
      'number': '6.1',
      'title': 'Mendelian inheritance',
      'order': 1,
      'status': 'not_started',
      'breadcrumb': {
        'subject': {'id': 's1', 'code': 'biology', 'name': 'Biology'},
        'unit': {'id': 'u6', 'code': 'u6', 'number': 6, 'title': 'Genetics'},
      },
      'mastery': {
        'mastery_percent': 40,
        'mastery_level': 'weak',
        'is_weak': true,
      },
      'is_bookmarked': true,
    });

    expect(detail.unit.id, 'u6');
    expect(detail.unit.order, 6);
    expect(detail.breadcrumbText, 'Biology › Unit 6 › Mendelian inheritance');
    expect(detail.masteryPercent, 40);
    expect(detail.masteryLevel, MasteryLevel.weak);
    expect(detail.saved, isTrue);
  });
}
