abstract final class AuthValidators {
  static final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isEmail(String value) => emailPattern.hasMatch(value.trim());

  static bool isPasswordValid(String value) {
    return value.length >= 8 &&
        RegExp(r'[A-Za-z]').hasMatch(value) &&
        RegExp(r'\d').hasMatch(value);
  }

  static bool passwordsMatch(String password, String confirm) {
    return password.isNotEmpty && password == confirm;
  }

  static bool canSubmitSignup({
    required String name,
    required String email,
    required String password,
    required String confirm,
    required bool termsAccepted,
    required bool privacyAccepted,
    required bool needsPassword,
  }) {
    if (name.trim().isEmpty || !isEmail(email)) return false;
    if (!termsAccepted || !privacyAccepted) return false;
    if (!needsPassword) return true;
    return isPasswordValid(password) && passwordsMatch(password, confirm);
  }
}
