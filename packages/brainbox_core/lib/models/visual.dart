import 'package:freezed_annotation/freezed_annotation.dart';

part 'visual.freezed.dart';
part 'visual.g.dart';

/// A diagram or image for a topic.
///
// TODO(mogith): check these fields against the backend OpenAPI /docs.
@freezed
abstract class Visual with _$Visual {
  const factory Visual({
    required String id,
    required String topicId,
    required String title,
    required String imageUrl,
    String? caption,
    @Default(false) bool isAiGenerated, // show AiBadge when true
  }) = _Visual;

  factory Visual.fromJson(Map<String, dynamic> json) => _$VisualFromJson(json);
}
