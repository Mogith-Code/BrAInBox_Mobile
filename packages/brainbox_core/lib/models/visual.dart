import 'package:freezed_annotation/freezed_annotation.dart';

part 'visual.freezed.dart';
part 'visual.g.dart';

/// What a [Visual] is (the backend's `VisualKind`).
///
/// - [diagram], [flowchart], [table]: drawn from [Visual.mermaidCode]
///   (Mermaid text), so labels are always spelled right.
/// - [illustration]: a picture from an image model, stored as a PNG.
enum VisualKind { diagram, flowchart, table, illustration }

/// One numbered label on a visual ("1 Bowman's capsule").
///
/// [x] and [y] are where the marker sits, as a fraction (0.0 - 1.0) of the
/// image width and height. They are null when the label has no fixed spot
/// (e.g. on a Mermaid diagram): the app then lists it under the visual.
@freezed
abstract class VisualLabel with _$VisualLabel {
  const factory VisualLabel({
    required int number,
    required String name,
    @Default('') String description,
    double? x,
    double? y,
  }) = _VisualLabel;

  factory VisualLabel.fromJson(Map<String, dynamic> json) =>
      _$VisualLabelFromJson(json);
}

/// A diagram or image for a topic (`VisualOut` on the backend).
///
/// The backend sends [imageUrl] (a rendered PNG) and/or [mermaidCode]. If
/// only [mermaidCode] is set, the app renders it itself.
@freezed
abstract class Visual with _$Visual {
  const Visual._();

  const factory Visual({
    required String id,
    required String title,
    String? topicId,
    String? conceptId,
    @JsonKey(unknownEnumValue: VisualKind.diagram)
    @Default(VisualKind.diagram)
    VisualKind kind,
    String? imageUrl,
    String? mermaidCode,
    String? altText, // read by TalkBack; also shown when there are no labels
    @Default([]) List<VisualLabel> labels,
    String? style, // "flat_colour", "textbook_line", "cross_section"
    int? width, // image size in pixels, used to place the label markers
    int? height,
    @Default(false) bool isAiGenerated, // show AiBadge when true
    @Default(false) bool isVerified, // checked by a teacher / admin
    DateTime? createdAt,
  }) = _Visual;

  factory Visual.fromJson(Map<String, dynamic> json) => _$VisualFromJson(json);

  /// Width / height of the image (4:3 when the backend doesn't say).
  double get aspectRatio =>
      (width ?? 0) > 0 && (height ?? 0) > 0 ? width! / height! : 4 / 3;

  bool get hasLabels => labels.isNotEmpty;
}
