import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_models.dart';
import 'auth_flow_controllers.dart';
import 'session_controller.dart';

part 'inbox_controller.g.dart';

/// Everything "Check your inbox" shows.
class InboxState {
  const InboxState({
    this.secondsLeft = 0,
    this.sending = false,
    this.verifying = false,
    this.error,
    this.errorCode,
    this.devCode,
  });

  /// Countdown before "Resend code" is allowed.
  final int secondsLeft;
  final bool sending;
  final bool verifying;

  /// Friendly error under the code boxes.
  final String? error;
  final String? errorCode;

  /// Debug builds only: the code the backend exposed (`dev_code`).
  final String? devCode;

  bool get canResend => secondsLeft == 0 && !sending;

  /// The code can't be used any more - the student must ask for a new one.
  bool get needsNewCode =>
      errorCode == 'CODE_EXPIRED' || errorCode == 'TOO_MANY_ATTEMPTS';

  InboxState copyWith({
    int? secondsLeft,
    bool? sending,
    bool? verifying,
    String? error,
    String? errorCode,
    String? devCode,
    bool clearError = false,
  }) => InboxState(
    secondsLeft: secondsLeft ?? this.secondsLeft,
    sending: sending ?? this.sending,
    verifying: verifying ?? this.verifying,
    error: clearError ? null : (error ?? this.error),
    errorCode: clearError ? null : (errorCode ?? this.errorCode),
    devCode: devCode ?? this.devCode,
  );
}

/// "Check your inbox" for both modes:
/// - verify email: POST /auth/email-code/verify -> refresh -> setup
/// - reset password: POST /auth/password-reset/verify -> reset token
///   (memory only) -> "Set a new password"
@riverpod
class InboxController extends _$InboxController {
  Timer? _timer;

  @override
  InboxState build(InboxMode mode) {
    ref.onDispose(() => _timer?.cancel());

    // Was a code sent recently (by Create account / Forgot password, or
    // before the screen was reopened)? Continue its countdown.
    final pending = ref.read(pendingCodeProvider(mode));
    if (pending != null) {
      final elapsed = DateTime.now().difference(pending.sentAt).inSeconds;
      final left = pending.code.resendIn - elapsed;
      if (elapsed < pending.code.expiresIn) {
        _startCountdown(left);
        return InboxState(
          secondsLeft: left < 0 ? 0 : left,
          devCode: pending.code.devCode,
        );
      }
    }

    // Opened without a fresh code (e.g. the app was restarted while the
    // email was still unverified): send one now.
    if (mode == InboxMode.verifyEmail) Future.microtask(resend);
    return const InboxState();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.secondsLeft - 1;
      state = state.copyWith(secondsLeft: left < 0 ? 0 : left);
      if (left <= 0) t.cancel();
    });
  }

  /// Sends a new code (and restarts the countdown).
  Future<void> resend() async {
    if (state.sending) return;
    final repo = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    final pending = ref.read(pendingCodeProvider(mode).notifier);
    final email = ref.read(resetFlowProvider).email;
    state = state.copyWith(sending: true, clearError: true);
    try {
      final code = mode == InboxMode.verifyEmail
          ? await repo.sendEmailCode()
          : await repo.sendResetCode(email);
      pending.set(code);
      if (!ref.mounted) return;
      state = InboxState(secondsLeft: code.resendIn, devCode: code.devCode);
      _startCountdown(code.resendIn);
    } on ApiException catch (e) {
      if (!ref.mounted) return;
      if (e.code == 'ALREADY_VERIFIED') {
        state = state.copyWith(sending: false);
        await repo.reloadAccount();
        await session.refresh();
        return;
      }
      final wait = e.code == 'RESEND_TOO_SOON' ? (e.retryAfter ?? 30) : null;
      state = state.copyWith(
        sending: false,
        secondsLeft: wait,
        error: ErrorMessages.of(e),
        errorCode: e.code,
      );
      if (wait != null) _startCountdown(wait);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(sending: false, error: ErrorMessages.of(e));
    }
  }

  /// Checks [code]. Returns true when it was right (the screen then moves
  /// on; in verify mode the router does it).
  Future<bool> verify(String code) async {
    if (state.verifying || Validators.otpCode(code) != null) return false;
    final repo = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    final flow = ref.read(resetFlowProvider.notifier);
    final email = ref.read(resetFlowProvider).email;
    state = state.copyWith(verifying: true, clearError: true);
    try {
      if (mode == InboxMode.verifyEmail) {
        try {
          await repo.verifyEmailCode(code);
        } on ApiException catch (e) {
          // Verified already (e.g. on another phone): just move on.
          if (e.code != 'ALREADY_VERIFIED') rethrow;
        }
        await repo.reloadAccount();
        await session.refresh();
      } else {
        final token = await repo.verifyResetCode(email: email, code: code);
        flow.setToken(token.resetToken);
      }
      if (ref.mounted) state = state.copyWith(verifying: false);
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      final apiCode = e is ApiException ? e.code : null;
      state = state.copyWith(
        verifying: false,
        error: ErrorMessages.of(e),
        errorCode: apiCode,
        // A dead code can be replaced right away.
        secondsLeft: apiCode == 'CODE_EXPIRED' || apiCode == 'TOO_MANY_ATTEMPTS'
            ? 0
            : null,
      );
      if (state.needsNewCode) _timer?.cancel();
      return false;
    }
  }

  /// Hides the error once the student edits the code (unless the code is
  /// dead and a new one is needed).
  void clearError() {
    if (state.error != null && !state.needsNewCode) {
      state = state.copyWith(clearError: true);
    }
  }

  /// "Wrong email? Change it" in verify mode: removes the unverified
  /// account (DELETE /auth/me + Firebase) so the student can sign up again.
  Future<void> discardUnverifiedAccount() async {
    final repo = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);
    await repo.deleteAccount();
    await session.refresh();
  }
}
