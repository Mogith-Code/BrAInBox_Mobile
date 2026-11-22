/// Not on the web (tests, desktop debug runs): there is no browser to save
/// with. The admin portal itself only runs on the web.
Future<void> saveTextFile(
  String fileName,
  String text, {
  String mimeType = 'text/csv',
}) => throw UnsupportedError('Downloads only work in the browser.');
