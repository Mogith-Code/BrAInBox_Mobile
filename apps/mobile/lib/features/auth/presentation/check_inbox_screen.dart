import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/auth_flow_controllers.dart';
import '../application/inbox_controller.dart';
import '../application/session_controller.dart';
import '../application/session_redirect.dart';
import '../domain/auth_models.dart';
import 'widgets/auth_layout.dart';

/// Check your inbox (Figma A8) - type the 6-digit code.
///
/// Routes:
/// - `/auth/verify-email` ([InboxMode.verifyEmail]) after sign up
/// - `/auth/reset-code` ([InboxMode.resetPassword]) after "Forgot password"
class CheckInboxScreen extends ConsumerStatefulWidget {
  const CheckInboxScreen({super.key, required this.mode});

  final InboxMode mode;

  @override
  ConsumerState<CheckInboxScreen> createState() => _CheckInboxScreenState();
}

class _CheckInboxScreenState extends ConsumerState<CheckInboxScreen> {
  final _code = TextEditingController();

  bool get _isReset => widget.mode == InboxMode.resetPassword;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String get _email => _isReset
      ? ref.watch(resetFlowProvider).email
      : (ref.watch(sessionProvider).value?.user?.email ?? '');

  Future<void> _verify(String code) async {
    final ok = await ref
        .read(inboxControllerProvider(widget.mode).notifier)
        .verify(code);
    if (!ok || !mounted) return;
    if (_isReset) {
      unawaited(context.push(AppRoutes.newPassword));
    } else {
      // Next stop: profile setup (or wherever the redirect table says).
      final session = ref.read(sessionProvider).value;
      context.go(session == null ? AppRoutes.splash : targetFor(session));
    }
  }

  Future<void> _changeEmail() async {
    if (_isReset) {
      context.canPop() ? context.pop() : context.go(AppRoutes.forgotPassword);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use a different email?'),
        content: const Text(
          "We'll remove this unverified sign-up so you can create your "
          'account again with the right email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change email'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(inboxControllerProvider(widget.mode).notifier)
        .discardUnverifiedAccount();
    if (mounted) context.go(AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inboxControllerProvider(widget.mode));
    final controller = ref.read(inboxControllerProvider(widget.mode).notifier);
    final textTheme = Theme.of(context).textTheme;
    final email = _email;

    return AuthLayout(
      onBack: _changeEmail,
      footer: InlineLink(
        text: 'Wrong email?',
        link: 'Change it',
        onTap: _changeEmail,
      ),
      children: [
        const SizedBox(height: AppSpacing.sm),
        const Align(
          alignment: Alignment.centerLeft,
          child: IconTile(
            icon: Icons.notifications_none_rounded,
            color: AppColors.successDark,
            background: AppColors.successSoft,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ScreenHeading(
          title: 'Check your inbox',
          subtitle: Text.rich(
            TextSpan(
              style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
              children: [
                TextSpan(
                  text: _isReset
                      ? 'If an account exists, we sent a 6-digit code to\n'
                      : 'We sent a 6-digit code to\n',
                ),
                TextSpan(
                  text: email,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        OtpCodeField(
          controller: _code,
          hasError: state.error != null && state.errorCode != null,
          enabled: !state.verifying,
          onChanged: (_) => controller.clearError(),
          onCompleted: _verify,
        ),
        if (state.error != null) ...[
          const SizedBox(height: AppSpacing.md),
          FormErrorText(state.error),
        ] else
          const SizedBox(height: AppSpacing.lg),
        _ResendRow(state: state, onResend: controller.resend),
        DevCodeStrip(
          code: state.devCode,
          onUse: () {
            _code.text = state.devCode!;
            _verify(state.devCode!);
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        ValueListenableBuilder(
          valueListenable: _code,
          builder: (context, value, _) => AppButton(
            label: 'Verify',
            isLoading: state.verifying,
            onPressed: value.text.length == 6 && !state.needsNewCode
                ? () => _verify(value.text)
                : null,
          ),
        ),
      ],
    );
  }
}

/// "Resend code in 0:42" -> "Resend code" link when the timer ends.
class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.state, required this.onResend});

  final InboxState state;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted);

    if (state.sending) {
      return Center(child: Text('Sending a new code…', style: style));
    }
    if (!state.canResend) {
      return Center(
        child: Semantics(
          liveRegion: false,
          label: 'You can resend the code in ${state.secondsLeft} seconds',
          child: ExcludeSemantics(
            child: Text.rich(
              TextSpan(
                style: style,
                children: [
                  const TextSpan(text: 'Resend code in '),
                  TextSpan(
                    text: Formatters.countdown(state.secondsLeft),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Center(
      child: TextButton(
        onPressed: onResend,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        child: const Text('Resend code'),
      ),
    );
  }
}
