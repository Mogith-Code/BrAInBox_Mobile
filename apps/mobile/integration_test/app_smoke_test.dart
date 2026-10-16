// Runs on a real device or emulator:
//   cd apps/mobile && flutter test integration_test
import 'package:brainbox_mobile/features/splash/presentation/splash_screen.dart';
import 'package:brainbox_mobile/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and shows the splash screen', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
