import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_models.dart';
import 'session_controller.dart';

part 'auth_flow_controllers.g.dart';

// Controllers for the auth forms. Each one holds AsyncValue<void>:
//   AsyncData   -> idle / done
//   AsyncLoading -> the button shows a spinner
//   AsyncError  -> the screen shows ErrorMessages.of(error)
// After a successful sign in / sign up they refresh the Session, and the
// router's redirect takes the student to the right next screen.

/// A code that was just sent, and when.
typedef SentCode = ({CodeSent code, DateTime sentAt});

/// The last code that was sent, so "Check your inbox" can continue its
/// countdown (and show the debug code) without sending a second one.
/// In memory only.
@Riverpod(keepAlive: true)
class PendingCode extends _$PendingCode {
  @override
  SentCode? build(InboxMode mode) => null;

  void set(CodeSent code) => state = (code: code, sentAt: DateTime.now());
}

/// Create account: Firebase account -> display name -> POST /auth/register
/// -> POST /auth/email-code/send -> (router) Check your inbox.
@riverpod
class SignupController extends _$SignupController {
  @override
  FutureOr<void> build() {}

  Future<bool> submit({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    final pending = ref.read(
      pendingCodeProvider(InboxMode.verifyEmail).notifier,
    );
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      // If a previous try already created the Firebase account (e.g. the
      // register call failed), don't create it again - just retry the rest.
      if (repo.currentAccount?.email.toLowerCase() != email.toLowerCase()) {
        await repo.signUp(fullName: fullName, email: email, password: password);
      }
      await repo.register(fullName: fullName, phone: phone, consent: true);
      try {
        pending.set(await repo.sendEmailCode());
      } on ApiException catch (e) {
        // A recent code is still valid - "Check your inbox" shows the wait.
        if (e.code != 'RESEND_TOO_SOON') rethrow;
      }
      await session.refresh();
    });
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

/// Log in with email + password.
@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<void> build() {}

  Future<bool> submit({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await repo.signIn(email: email, password: password);
      // Session loads GET /auth/me (and registers on 404).
      await session.refresh();
    });
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

/// "Sign up with Google" / "Continue with Google".
@riverpod
class GoogleSignInController extends _$GoogleSignInController {
  @override
  FutureOr<void> build() {}

  Future<bool> submit() async {
    final repo = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await repo.signInWithGoogle();
      // Tapping Google means agreeing to the data notice shown under it.
      await repo.register(
        fullName: repo.currentAccount?.displayName ?? '',
        consent: true,
      );
      await session.refresh();
    });
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

/// In-memory state of a password reset: the email, then the reset token.
/// NEVER saved to the device.
class ResetFlowState {
  const ResetFlowState({this.email = '', this.resetToken});

  final String email;
  final String? resetToken;
}

@Riverpod(keepAlive: true)
class ResetFlow extends _$ResetFlow {
  @override
  ResetFlowState build() => const ResetFlowState();

  void start(String email) => state = ResetFlowState(email: email);

  void setToken(String token) =>
      state = ResetFlowState(email: state.email, resetToken: token);

  void clear() => state = const ResetFlowState();
}

/// Forgot password: POST /auth/password-reset/send.
@riverpod
class ForgotPasswordController extends _$ForgotPasswordController {
  @override
  FutureOr<void> build() {}

  Future<bool> submit(String email) async {
    final repo = ref.read(authRepositoryProvider);
    final flow = ref.read(resetFlowProvider.notifier);
    final pending = ref.read(
      pendingCodeProvider(InboxMode.resetPassword).notifier,
    );
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      flow.start(email);
      try {
        pending.set(await repo.sendResetCode(email));
      } on ApiException catch (e) {
        // A code was sent a moment ago: go on, the inbox shows the wait.
        if (e.code != 'RESEND_TOO_SOON') rethrow;
      }
    });
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

/// Set a new password: POST /auth/password-reset/complete, then sign in
/// with the new password.
@riverpod
class NewPasswordController extends _$NewPasswordController {
  @override
  FutureOr<void> build() {}

  Future<bool> submit(String newPassword) async {
    final flow = ref.read(resetFlowProvider);
    final flowNotifier = ref.read(resetFlowProvider.notifier);
    final repo = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final token = flow.resetToken;
      if (token == null) {
        throw const ApiException(
          code: 'RESET_TOKEN_INVALID',
          message: 'Please start again.',
        );
      }
      await repo.completeReset(resetToken: token, newPassword: newPassword);
      await repo.signIn(email: flow.email, password: newPassword);
      flowNotifier.clear();
      await session.refresh();
    });
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}
