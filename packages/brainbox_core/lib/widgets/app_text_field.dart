import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

/// The standard text input: a label above the field, an optional error
/// below, and an eye button for passwords.
///
/// ```dart
/// AppTextField(
///   label: 'Password',
///   controller: _password,
///   obscureText: true,
///   validator: Validators.password,
/// )
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.autofillHints,
    this.inputFormatters,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.prefix,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;

  /// Error shown under the field (e.g. from the server). For form validation
  /// use [validator] instead.
  final String? errorText;

  /// Hides the text and shows a show/hide toggle. Use for passwords.
  final bool obscureText;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final int maxLines;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  /// A widget shown before the text (e.g. "🇱🇰 +94" in `PhoneField`).
  final Widget? prefix;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          focusNode: widget.focusNode,
          textCapitalization: widget.textCapitalization,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: widget.prefix != null
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.lg,
                      end: AppSpacing.sm,
                    ),
                    child: widget.prefix,
                  )
                : widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon),
            prefixIconConstraints: widget.prefix != null
                ? const BoxConstraints(minWidth: 0, minHeight: 48)
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    tooltip: _obscured ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
