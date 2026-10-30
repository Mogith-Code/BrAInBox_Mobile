import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_logo.dart';
import '../application/auth_controller.dart';
import 'widgets/login_brand_panel.dart';

/// Admin login screen - Email + password sign-in. Non-admin accounts are refused.
///
/// Route: `/login`
///
/// Wide screens (>= [_splitBreakpoint]) show the gradient brand panel on the
/// left and the form on the right; narrow screens show only the form.
///
// TODO(mogith): wire the form to a real sign-in. Keep this file UI-only: read
// state from the controller and call its methods. Never call Dio / Firebase
// here.
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // TODO(mogith): call a signIn(email, password, keepSignedIn) method on
    // AuthController once the repository has one. The router guard then
    // opens the dashboard for admins.
    _showNotConnected('Sign-in is not connected yet.');
  }

  void _forgotPassword() {
    // TODO(mogith): open the password reset flow once it exists.
    _showNotConnected('Password reset is not connected yet.');
  }

  void _showNotConnected(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(authControllerProvider),
          ),
        ),
        data: (_) => LayoutBuilder(
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
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool showLogo}) {
    final textTheme = Theme.of(context).textTheme;
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
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(label: 'Sign in to console', onPressed: _submit),
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
