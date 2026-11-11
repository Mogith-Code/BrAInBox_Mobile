import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_logo.dart';
import '../application/auth_controller.dart';
import 'widgets/login_brand_panel.dart';

/// Admin login screen - Email + password sign-in. Non-admin accounts are refused
/// ("This account is not an admin").
///
/// Route: `/login`
///
/// Wide screens (>= [_splitBreakpoint]) show the gradient brand panel on the
/// left and the form on the right; narrow screens show only the form.
/// After a good sign-in the router guard opens the dashboard.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const double _splitBreakpoint = 900;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _keepSignedIn = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (ref.read(authControllerProvider).isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _email.text,
          password: _password.text,
          keepSignedIn: _keepSignedIn,
        );
  }

  /// Admins use the same account as the app, so the app's 6-digit reset
  /// flow works for them too.
  void _forgotPassword() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset your password'),
        content: const Text(
          'Open the BrAInBox app, tap "Forgot password?" on the log in '
          'screen and use the 6-digit code we email you. Then sign in here '
          'with the new password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final split = constraints.maxWidth >= LoginScreen._splitBreakpoint;
          final form = _buildForm(context, showLogo: !split);
          if (!split) return form;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(flex: 9, child: LoginBrandPanel()),
              Expanded(flex: 11, child: form),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool showLogo}) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(authControllerProvider);
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showLogo) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: AdminLogo(),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    Semantics(
                      header: true,
                      child: Text('Sign in', style: textTheme.headlineSmall),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text.rich(
                      const TextSpan(
                        text: 'Use your ',
                        children: [
                          TextSpan(
                            text: 'institution email',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Email',
                      controller: _email,
                      hint: 'you@institution.lk',
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Password',
                      controller: _password,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      // Sign-in only checks it is filled in; the strength
                      // rules in Validators.password are for sign-up.
                      validator: (value) =>
                          Validators.requiredField(value, field: 'Password'),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: MergeSemantics(
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _keepSignedIn,
                                  onChanged: (value) => setState(
                                    () => _keepSignedIn = value ?? false,
                                  ),
                                ),
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _keepSignedIn = !_keepSignedIn,
                                    ),
                                    child: Text(
                                      'Keep me signed in',
                                      style: textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _forgotPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                    if (state.hasError) ...[
                      const SizedBox(height: AppSpacing.md),
                      ErrorBanner(
                        message: AuthController.messageFor(state.error!),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Sign in to console',
                      isLoading: state.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
