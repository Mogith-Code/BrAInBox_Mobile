import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/auth_flow_controllers.dart';
import 'widgets/auth_layout.dart';

/// Forgot your password? (Figma A7)
///
/// Route: `/auth/forgot-password`. Sends a 6-digit reset code, then opens
/// "Check your inbox" in reset mode.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(
    text: ref.read(resetFlowProvider).email,
  );

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_email.text.trim());
    if (ok && mounted) unawaited(context.push(AppRoutes.resetCode));
  }

  void _backToLogin() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);

    return AuthLayout(
      onBack: _backToLogin,
      footer: InlineLink(
        text: 'Remembered it?',
        link: 'Back to log in',
        onTap: _backToLogin,
      ),
      children: [
        const SizedBox(height: AppSpacing.sm),
        const Align(
          alignment: Alignment.centerLeft,
          child: IconTile(icon: Icons.verified_user_outlined),
        ),
        const SizedBox(height: AppSpacing.xl),
        const ScreenHeading(
          title: 'Forgot your password?',
          subtitle:
              "No stress. Enter your email and we'll send a 6-digit code to "
              'reset it.',
        ),
        const SizedBox(height: AppSpacing.xl),
        Form(
          key: _form,
          child: AppTextField(
            label: 'Email',
            controller: _email,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FormErrorText(state.hasError ? ErrorMessages.of(state.error) : null),
        AppButton(
          label: 'Send code',
          isLoading: state.isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
