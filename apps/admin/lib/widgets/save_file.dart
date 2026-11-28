import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'save_file_stub.dart'
    if (dart.library.js_interop) 'save_file_web.dart'
    as impl;

/// Hands [text] to the browser as a download called [fileName].
typedef SaveTextFile =
    Future<void> Function(String fileName, String text, {String mimeType});

/// The browser download, as a provider so tests can catch the file instead.
final saveTextFileProvider = Provider<SaveTextFile>((ref) => impl.saveTextFile);
