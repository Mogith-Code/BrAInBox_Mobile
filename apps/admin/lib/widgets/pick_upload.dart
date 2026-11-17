import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A file the admin picked, read into memory (Flutter web has no paths).
class PickedUpload {
  const PickedUpload({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

/// Opens the browser's file dialog for one of [extensions] (no dots).
/// Returns null when the admin cancels.
typedef PickUpload = Future<PickedUpload?> Function(List<String> extensions);

/// The file dialog, as a provider so tests can hand in a file instead.
final pickUploadProvider = Provider<PickUpload>((ref) => _pick);

Future<PickedUpload?> _pick(List<String> extensions) async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: extensions,
  );
  if (file == null) return null;
  return PickedUpload(name: file.name, bytes: await file.readAsBytes());
}
