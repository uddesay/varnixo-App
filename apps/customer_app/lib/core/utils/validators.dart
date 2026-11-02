/// Client-side validation mirroring (but not replacing) the backend's Joi
/// schemas — good UX gives instant feedback, but the server remains the
/// source of truth.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phone = RegExp(r'^\+?[1-9]\d{7,14}$');
  static final RegExp _password =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

  static bool isEmail(String value) => _email.hasMatch(value.trim());
  static bool isPhone(String value) => _phone.hasMatch(value.trim());

  static bool isIdentifier(String value) =>
      isEmail(value) || isPhone(value);

  static String? identifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email or phone number';
    }
    if (!isIdentifier(value)) return 'Enter a valid email or phone number';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    if (!_password.hasMatch(value)) {
      return 'At least 8 characters with upper, lower and a digit';
    }
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Enter your full name';
    }
    return null;
  }

  static String? otp(String? value) {
    if (value == null || !RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Enter the 6-digit code';
    }
    return null;
  }

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }
}
