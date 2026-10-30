import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/auth_flow_controllers.dart';
import 'widgets/auth_layout.dart';

/// Set a new password (not in Figma - built in the style of A7).
///
/// Route: `/auth/new-password`, after a correct reset code. Saves the new
/// password, signs in with it, and the router takes the student on.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(newPasswordControllerProvider.notifier)
        .submit(_password.text);
    if (ok && mounted) context.go(AppRoutes.splash);
  }

  void _startAgain() {
    ref.read(resetFlowProvider.notifier).clear();
    context.go(AppRoutes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newPasswordControllerProvider);
    final email = ref.watch(resetFlowProvider).email;
    final error = state.error;
    final tokenInvalid =
        error is ApiException && error.code == 'RESET_TOKEN_INVALID';
    final textTheme = Theme.of(context).textTheme;

    return AuthLayout(
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(AppRoutes.forgotPassword),
      footer: InlineLink(
        text: 'Remembered it?',
        link: 'Back to log in',
        onTap: () => context.go(AppRoutes.login),
      ),
      children: [
        const SizedBox(height: AppSpacing.sm),
        const Align(
          alignment: Alignment.centerLeft,
          child: IconTile(icon: Icons.lock_reset_rounded),
        ),
        const SizedBox(height: AppSpacing.xl),
        ScreenHeading(
          title: 'Set a new password',
          subtitle: Text.rich(
            TextSpan(
              style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
              children: [
                const TextSpan(text: 'Choose a new password for '),
                TextSpan(
                  text: email.isEmpty ? 'your account' : email,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'New password',
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordStrengthMeter(password: _password.text),
              kFieldGap,
              AppTextField(
                label: 'Confirm password',
                controller: _confirm,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => Validators.confirmPassword(v, _password.text),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (tokenInvalid) ...[
          FormErrorText(ErrorMessages.of(error)),
          AppButton(label: 'Start again', onPressed: _startAgain),
        ] else ...[
          FormErrorText(state.hasError ? ErrorMessages.of(error) : null),
          AppButton(
            label: 'Save',
            isLoading: state.isLoading,
            onPressed: _submit,
          ),
        ],
      ],
    );
  }
}
