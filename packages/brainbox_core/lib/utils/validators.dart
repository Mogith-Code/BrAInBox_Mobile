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
