/// How strong a password is, for the strength meter on sign up and
/// "Set a new password".
///
/// This is only a hint for the student. The real rule (checked by
/// `Validators.password`) is: at least 8 characters with a letter and a
/// number.
enum PasswordStrength {
  empty(0, ''),
  weak(1, 'Weak'),
  fair(2, 'Fair'),
  good(3, 'Good'),
  strong(4, 'Strong');

  const PasswordStrength(this.score, this.label);

  /// 0 - 4: how many meter segments are filled.
  final int score;

  /// Shown under the meter ("Good").
  final String label;

  /// Scores [password] and returns the strength.
  static PasswordStrength of(String password) {
    if (password.isEmpty) return PasswordStrength.empty;

    final hasLower = RegExp('[a-z]').hasMatch(password);
    final hasUpper = RegExp('[A-Z]').hasMatch(password);
    final hasDigit = RegExp('[0-9]').hasMatch(password);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
    final hasLetter = hasLower || hasUpper;

    // Below the minimum rule is always weak.
    if (password.length < 8 || !hasLetter || !hasDigit) {
      return PasswordStrength.weak;
    }

    var points = 0;
    if (hasLower && hasUpper) points++;
    if (hasSymbol) points++;
    if (password.length >= 12) points++;

    return switch (points) {
      0 => PasswordStrength.fair,
      1 => PasswordStrength.good,
      _ => PasswordStrength.strong,
    };
  }

  /// One short tip for making [password] stronger, or '' when it is strong.
  static String hintFor(String password) {
    final strength = of(password);
    if (strength == PasswordStrength.empty) {
      return 'At least 8 characters with a letter and a number';
    }
    if (password.length < 8) return 'Use at least 8 characters';
    if (!RegExp('[A-Za-z]').hasMatch(password)) return 'Add a letter';
    if (!RegExp('[0-9]').hasMatch(password)) return 'Add a number';
    if (strength == PasswordStrength.strong) return '';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Add a symbol to make it stronger';
    }
    if (!(RegExp('[a-z]').hasMatch(password) &&
        RegExp('[A-Z]').hasMatch(password))) {
      return 'Mix upper and lower case to make it stronger';
    }
    return 'Make it longer to make it stronger';
  }
}
