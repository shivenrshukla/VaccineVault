class Validators {
  // Validator for a generic name or username field
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty.';
    }
    if (value.length < 3) {
      return 'Must be at least 3 characters long.';
    }
    return null;
  }

  // Validator for an email field
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty.';
    }
    // Regular expression for basic email validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  // Validator for a password field
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    // You could add more complex rules here (e.g., require numbers, symbols)
    return null;
  }

  // Validator to confirm that the password and confirmation fields match
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  // Validator for phone number (10 digits)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number cannot be empty.';
    }
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Must be a valid 10-digit phone number.';
    }
    return null;
  }

  // Validator for date format (YYYY-MM-DD)
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of birth cannot be empty.';
    }
    // This simple check is sufficient since the date picker enforces the format.
    return null;
  }

  // Validator for a generic address field
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }

  // Validator for a city field
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'City cannot be empty.';
    }
    return null;
  }

  // Validator for a state field
  static String? validateState(String? value) {
    if (value == null || value.isEmpty) {
      return 'State cannot be empty.';
    }
    return null;
  }

  // Validator for PIN code (6 digits)
  static String? validatePinCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN code cannot be empty.';
    }
    final pinRegex = RegExp(r'^[0-9]{6}$');
    if (!pinRegex.hasMatch(value)) {
      return 'Must be a valid 6-digit PIN code.';
    }
    return null;
  }
}