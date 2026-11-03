import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/validators.dart';
import 'app_text_field.dart';

/// Sri Lankan mobile number with a fixed "🇱🇰 +94" prefix.
///
/// The student types "77 123 4567". Use
/// `Validators.normalizeSriLankanMobile(text)` to get "+94771234567"
/// before sending it to the backend. Optional unless [required] is true.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    this.label = 'Phone',
    this.controller,
    this.required = false,
    this.textInputAction,
    this.onChanged,
    this.errorText,
  });

  final String label;
  final TextEditingController? controller;
  final bool required;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  /// An error from outside the form (e.g. the backend's `INVALID_PHONE`).
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      hint: '77 123 4567',
      errorText: errorText,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]')),
        LengthLimitingTextInputFormatter(15),
      ],
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Phone number is required';
        }
        return Validators.sriLankanMobile(value);
      },
      prefix: Semantics(
        label: 'Sri Lanka, plus 94',
        child: const ExcludeSemantics(
          child: Text(
            '🇱🇰  +94',
            // height 1 keeps the flag from pushing "+94" above the text line.
            style: TextStyle(fontSize: 16, height: 1),
          ),
        ),
      ),
    );
  }
}
