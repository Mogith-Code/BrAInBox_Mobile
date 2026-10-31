import 'dart:convert';
import 'dart:io' show ZLibEncoder;

import '../domain/visuals_models.dart';

/// Turns Mermaid text into an image URL using Kroki (https://kroki.io), a
/// free, open-source diagram renderer. The diagram text goes in the URL
/// (zlib-compressed, base64url), so no API key and no upload are needed.
///
/// Point it at your own Kroki server with
/// `--dart-define=DIAGRAM_RENDER_URL=http://10.0.2.2:8001`
/// (Docker: `docker run -p 8001:8000 yuzutech/kroki` + the mermaid companion).
abstract final class DiagramRenderer {
  static const String baseUrl = String.fromEnvironment(
    'DIAGRAM_RENDER_URL',
    defaultValue: 'https://kroki.io',
  );

  /// PNG of a Mermaid diagram, e.g. `https://kroki.io/mermaid/png/eNpL...`.
  static String mermaidPngUrl(String code) {
    final packed = ZLibEncoder(level: 9).convert(utf8.encode(code.trim()));
    return '$baseUrl/mermaid/png/${base64Url.encode(packed)}';
  }

  /// The image to show for [visual]: the backend's PNG when it has one,
  /// otherwise its Mermaid code rendered by Kroki. Null if it has neither.
  static String? imageUrlOf(Visual visual) {
    final url = visual.imageUrl;
    if (url != null && url.isNotEmpty) return url;
    final code = visual.mermaidCode;
    if (code != null && code.trim().isNotEmpty) return mermaidPngUrl(code);
    return null;
  }
}
