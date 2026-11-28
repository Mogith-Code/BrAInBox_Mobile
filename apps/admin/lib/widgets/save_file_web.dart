import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Saves [text] (UTF-8, with a byte-order mark so Excel reads Sinhala and
/// Tamil names correctly) through a temporary download link.
Future<void> saveTextFile(
  String fileName,
  String text, {
  String mimeType = 'text/csv',
}) async {
  final bytes = utf8.encode('﻿$text');
  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: '$mimeType;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(link);
  link.click();
  link.remove();
  web.URL.revokeObjectURL(url);
}
