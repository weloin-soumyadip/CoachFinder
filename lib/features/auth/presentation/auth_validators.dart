/// Form-field validators shared across the auth screens.
library;

import '../../../core/constants/app_strings.dart';

/// Reusable `TextFormField` validators returning a localized error message, or
/// `null` when the value is valid.
abstract final class AuthValidators {
  AuthValidators._();

  /// Non-empty check.
  static String? notEmpty(String? value) {
    return (value == null || value.trim().isEmpty)
        ? AppStrings.validatorRequired
        : null;
  }

  /// Required + basic email-format check.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.validatorRequired;
    }
    final RegExp pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return pattern.hasMatch(value.trim()) ? null : AppStrings.validatorEmail;
  }

  /// Required + minimum length of 8 characters.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.validatorRequired;
    return value.length < 8 ? AppStrings.validatorPasswordShort : null;
  }

  /// Required + must equal [original] (for confirm-password fields).
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return AppStrings.validatorRequired;
    return value == original ? null : AppStrings.validatorPasswordMatch;
  }
}
