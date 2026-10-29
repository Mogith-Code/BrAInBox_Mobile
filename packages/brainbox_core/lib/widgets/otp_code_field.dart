import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Six boxes for a 6-digit code ("Check your inbox").
///
/// How it works: one invisible text field holds the digits and the boxes
/// just draw them. That gives us for free:
/// - auto-advance (the next box lights up as you type),
/// - backspace across boxes,
/// - pasting a whole 6-digit code (also "123 456" or "123-456"),
/// - the SMS / email one-time-code autofill on Android.
///
/// [onCompleted] fires as soon as 6 digits are entered.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = true,
    this.controller,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  /// Draws the boxes with a red border (wrong code).
  final bool hasError;
  final bool enabled;
  final bool autofocus;

  /// Optional, e.g. to clear the code after an error.
  final TextEditingController? controller;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _handleChanged(String raw) {
    // Keep digits only, so pasting "482 715" or "482-715" works too.
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final code = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    if (code != raw) {
      _controller.value = TextEditingValue(
        text: code,
        selection: TextSelection.collapsed(offset: code.length),
      );
    }
    setState(() {});
    widget.onChanged?.call(code);
    if (code.length == widget.length) widget.onCompleted?.call(code);
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    return Semantics(
      label: 'Verification code, ${widget.length} digits',
      textField: true,
      child: Stack(
        children: [
          // The boxes.
          Row(
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _Box(
                    digit: i < code.length ? code[i] : '',
                    isActive:
                        _focus.hasFocus &&
                        (i == code.length ||
                            (code.length == widget.length &&
                                i == widget.length - 1)),
                    hasError: widget.hasError,
                  ),
                ),
              ],
            ],
          ),
          // The invisible field on top catches taps, typing and paste.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                key: const ValueKey('otp-input'),
                controller: _controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                showCursor: false,
                enableInteractiveSelection: true,
                // Allow a few extra characters so a pasted "482 715" fits;
                // _handleChanged strips them.
                inputFormatters: [
                  LengthLimitingTextInputFormatter(widget.length + 4),
                ],
                onChanged: _handleChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.digit,
    required this.isActive,
    required this.hasError,
  });

  final String digit;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    if (hasError) {
      borderColor = AppColors.error;
    } else if (isActive) {
      borderColor = AppColors.primary;
    } else if (digit.isNotEmpty) {
      borderColor = AppColors.primaryLight;
    } else {
      borderColor = AppColors.border;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1.2),
      ),
      child: Text(
        digit,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
