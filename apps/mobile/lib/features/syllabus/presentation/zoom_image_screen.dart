import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import 'widgets/media_cards.dart';

/// Full-screen pinch-to-zoom view of a diagram or figure.
class ZoomImageScreen extends StatelessWidget {
  const ZoomImageScreen({super.key, required this.url, this.caption, this.heroTag});

  final String url;
  final String? caption;
  final String? heroTag;

  /// Opens above the bottom navigation.
  static Future<void> open(
    BuildContext context, {
    required String url,
    String? caption,
    String? heroTag,
  }) => Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ZoomImageScreen(url: url, caption: caption, heroTag: heroTag),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final image = InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: Center(child: DiagramImage(url: url)),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.white,
        title: caption == null
            ? null
            : Text(caption!, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: heroTag == null ? image : Hero(tag: heroTag!, child: image),
      ),
    );
  }
}
