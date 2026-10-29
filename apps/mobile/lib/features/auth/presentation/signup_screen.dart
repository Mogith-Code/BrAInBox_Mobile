import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../application/auth_flow_controllers.dart';
import 'widgets/auth_layout.dart';

// TODO(mogith): replace with the real privacy policy page.
const _privacyPolicyUrl = 'https://brainbox.lk/privacy';

/// Create your account (Figma A5).
///
/// Route: `/auth/signup`. On success the student lands on "Check your
/// inbox" (verify-email mode).
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _consent = false;
  bool _showConsentError = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formOk = _form.currentState?.validate() ?? false;
    setState(() => _showConsentError = !_consent);
    if (!formOk || !_consent) return;

    final ok = await ref
        .read(signupControllerProvider.notifier)
        .submit(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          phone: _phone.text.trim().isEmpty
              ? null
              : Validators.normalizeSriLankanMobile(_phone.text),
        );
    if (ok && mounted) context.go(AppRoutes.verifyEmail);
  }

  Future<void> _google() async {
    final ok = await ref.read(googleSignInControllerProvider.notifier).submit();
    // The router's redirect picks the next screen (setup or home).
    if (ok && mounted) context.go(AppRoutes.splash);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupControllerProvider);
    final google = ref.watch(googleSignInControllerProvider);
    final busy = state.isLoading || google.isLoading;
    final error = state.hasError
        ? ErrorMessages.of(state.error)
        : google.hasError
        ? ErrorMessages.of(google.error)
        : null;
    final textTheme = Theme.of(context).textTheme;

    return AuthLayout(
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.onboarding),
      footer: InlineLink(
        text: 'Already have an account?',
        link: 'Log in',
        onTap: () => context.go(AppRoutes.login),
      ),
      children: [
        const SizedBox(height: AppSpacing.sm),
        const ScreenHeading(
          title: 'Create your account',
          subtitle: 'Takes less than a minute.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Full name',
                  controller: _name,
                  hint: 'Nethmi Perera',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.fullName,
                ),
                kFieldGap,
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
                PhoneField(
                  controller: _phone,
                  textInputAction: TextInputAction.next,
                ),
                kFieldGap,
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.md),
                PasswordStrengthMeter(password: _password.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ConsentRow(
          value: _consent,
          showError: _showConsentError,
          onChanged: (v) => setState(() {
            _consent = v;
            if (v) _showConsentError = false;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        FormErrorText(error),
        AppButton(
          label: 'Create account',
          isLoading: state.isLoading,
          onPressed: busy ? null : _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        const OrDivider(),
        const SizedBox(height: AppSpacing.md),
        GoogleSignInButton(
          label: 'Sign up with Google',
          isLoading: google.isLoading,
          onPressed: busy ? null : _google,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'By continuing with Google you agree to how your learning data is used.',
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

/// "☑ I agree to how my learning data is used. Privacy policy"
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.showError,
    required this.onChanged,
  });

  final bool value;
  final bool showError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 48,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.primary,
                side: BorderSide(
                  color: showError ? AppColors.error : AppColors.mutedLight,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                semanticLabel: 'I agree to how my learning data is used',
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text.rich(
                  TextSpan(
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                    children: [
                      const TextSpan(
                        text: 'I agree to how my learning data is used. ',
                      ),
                      TextSpan(
                        text: 'Privacy policy',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(
                            Uri.parse(_privacyPolicyUrl),
                            mode: LaunchMode.externalApplication,
                          ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              'Please agree to continue',
              style: textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
