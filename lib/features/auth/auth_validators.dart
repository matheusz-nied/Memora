import 'auth_text.dart';

class AuthValidators {
  const AuthValidators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AuthText.requiredField;
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) {
      return requiredError;
    }

    final email = value!.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return AuthText.invalidEmail;
    }

    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value);
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.length < 6) {
      return AuthText.shortPassword;
    }

    return null;
  }
}
