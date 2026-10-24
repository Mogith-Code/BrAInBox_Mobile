/// Form validators. Each returns an error message, or `null` when valid,
/// so they plug straight into `TextFormField.validator` / `AppTextField`.
///
/// ```dart
/// AppTextField(label: 'Email', validator: Validators.email)
/// ```
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Not empty.
  static String? requiredField(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  /// A valid-looking email address.
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  /// At least 8 characters with a letter and a number.
  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 8) return 'Use at least 8 characters';
    if (!RegExp('[A-Za-z]').hasMatch(text) || !RegExp('[0-9]').hasMatch(text)) {
      return 'Use at least one letter and one number';
    }
    return null;
  }

  /// A person's name: at least 2 letters.
  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Full name is required';
    if (text.replaceAll(RegExp(r'[^A-Za-z]'), '').length < 2) {
      return 'Enter your full name';
    }
    return null;
  }

  /// OPTIONAL Sri Lankan mobile number, typed after the fixed "+94".
  /// Accepts "77 123 4567", "0771234567", "771234567", "+94771234567".
  /// Empty is valid (the phone is optional).
  static String? sriLankanMobile(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (normalizeSriLankanMobile(text) == null) {
      return 'Enter a Sri Lankan mobile number, e.g. 77 123 4567';
    }
    return null;
  }

  /// "077 123 4567" -> "+94771234567". Returns null if it is not a valid
  /// Sri Lankan mobile number (9 digits starting with 7 after +94 / 0).
  static String? normalizeSriLankanMobile(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('94')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (!RegExp(r'^7[0-9]{8}$').hasMatch(digits)) return null;
    return '+94$digits';
  }

  /// Exactly 6 digits.
  static String? otpCode(String? value) {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value ?? '')) {
      return 'Enter the 6-digit code';
    }
    return null;
  }

  /// Same as [original]. Use as `(v) => Validators.confirmPassword(v, pass)`.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  /// A 4-digit A/L exam year, from this year up to 5 years ahead.
  static String? examYear(String? value, {DateTime? now}) {
    final year = int.tryParse(value?.trim() ?? '');
    final thisYear = (now ?? DateTime.now()).year;
    if (year == null) return 'Enter your exam year, e.g. ${thisYear + 1}';
    if (year < thisYear || year > thisYear + 5) {
      return 'Enter a year between $thisYear and ${thisYear + 5}';
    }
    return null;
  }
}
