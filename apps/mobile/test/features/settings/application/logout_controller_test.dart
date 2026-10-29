import 'package:brainbox_mobile/features/auth/application/auth_flow_controllers.dart';
import 'package:brainbox_mobile/features/auth/application/session_controller.dart';
import 'package:brainbox_mobile/features/settings/application/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_app.dart';

void main() {
  test('log out signs out and clears the session', () async {
    final c = fakeContainer();
    addTearDown(c.dispose);
    final login = c.listen(loginControllerProvider, (_, _) {});
    addTearDown(login.close);
    await c
        .read(loginControllerProvider.notifier)
        .submit(email: 'nethmi.p@gmail.com', password: 'Mito2027');
    expect((await c.read(sessionProvider.future)).signedIn, isTrue);

    final sub = c.listen(logoutControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(logoutControllerProvider.notifier).logout();

    expect(c.read(logoutControllerProvider).hasError, isFalse);
    final session = await c.read(sessionProvider.future);
    expect(session.signedIn, isFalse);
    expect(session.welcomeSeen, isTrue); // the welcome isn't shown again
  });
}
