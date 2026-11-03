import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/auth_flow_controllers.dart';
import '../application/session_controller.dart';
import 'widgets/auth_layout.dart';

/// Welcome back / log in (Figma A6).
///
/// Route: `/auth/login`. After logging in, the router's redirect sends the
/// student wherever they left off (inbox, setup, diagnostic or home).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_form.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(loginControllerProvider.notifier)
        .submit(email: _email.text.trim(), password: _password.text);
    // The redirect decides where to go next; splash waits for it.
    if (ok && mounted) context.go(AppRoutes.splash);
  }

  Future<void> _google() async {
    final ok = await ref.read(googleSignInControllerProvider.notifier).submit();
    if (ok && mounted) context.go(AppRoutes.splash);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final google = ref.watch(googleSignInControllerProvider);
    final busy = state.isLoading || google.isLoading;
    // Signed out by the app itself (e.g. the account was disabled).
    final reason = ref.watch(sessionProvider).value?.signedOutReason;
    final error = state.hasError
        ? ErrorMessages.of(state.error)
        : google.hasError
        ? ErrorMessages.of(google.error)
        : reason != null
        ? ErrorMessages.of(reason)
        : null;

    return AuthLayout(
      footer: InlineLink(
        text: 'New to BrAInBox?',
        link: 'Create account',
        onTap: () => context.go(AppRoutes.signup),
      ),
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Align(alignment: Alignment.centerLeft, child: AppLogo(size: 56)),
        const SizedBox(height: AppSpacing.xl),
        // TODO(mogith): the Figma subtitle adds the student's first name
        // ("..., Nethmi."). We don't know it before they log in.
        const ScreenHeading(
          title: 'Welcome back',
          subtitle: 'Your study plan missed you.',
        ),
        const SizedBox(height: AppSpacing.xl),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                kFieldGap,
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) =>
                      Validators.requiredField(v, field: 'Password'),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(AppRoutes.forgotPassword),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FormErrorText(error),
        AppButton(
          label: 'Log in',
          isLoading: state.isLoading,
          onPressed: busy ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        const OrDivider(),
        const SizedBox(height: AppSpacing.md),
        GoogleSignInButton(
          label: 'Continue with Google',
          isLoading: google.isLoading,
          onPressed: busy ? null : _google,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'By continuing with Google you agree to how your learning data is used.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}
