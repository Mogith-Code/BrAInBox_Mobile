// Runs after `melos bootstrap`.
//
// `lib/firebase_options.dart` holds Firebase keys, so it is NOT committed.
// To keep the apps compiling before someone runs `flutterfire configure`,
// this script copies `lib/firebase_options.dart.example` (a stub with no
// keys) to `lib/firebase_options.dart` - but only if the file is missing.
// It never overwrites a real config.
import 'dart:io';

void main() {
  const apps = ['apps/mobile', 'apps/admin'];
  for (final app in apps) {
    final target = File('$app/lib/firebase_options.dart');
    final example = File('$app/lib/firebase_options.dart.example');
    if (target.existsSync()) {
      stdout.writeln('$app: firebase_options.dart already exists, keeping it.');
    } else if (example.existsSync()) {
      example.copySync(target.path);
      stdout.writeln('$app: created firebase_options.dart from the stub.');
    }
  }
}
