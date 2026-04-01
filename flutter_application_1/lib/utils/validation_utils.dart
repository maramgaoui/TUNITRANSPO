import 'package:flutter/material.dart';

class ValidationUtils {
  // Email validation with real-time feedback
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email est requis';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  static bool isEmailValid(String? value) {
    if (value == null || value.isEmpty) return false;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(value);
  }

  // Password strength validation
  static PasswordStrength validatePasswordStrength(String? value) {
    if (value == null || value.isEmpty) {
      return PasswordStrength.empty;
    }

    int strength = 0;

    // Check length
    if (value.length >= 6) strength++;
    if (value.length >= 8) strength++;
    if (value.length >= 12) strength++;

    // Check for uppercase
    if (value.contains(RegExp(r'[A-Z]'))) strength++;

    // Check for lowercase
    if (value.contains(RegExp(r'[a-z]'))) strength++;

    // Check for numbers
    if (value.contains(RegExp(r'[0-9]'))) strength++;

    // Check for special characters
    if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    if (strength <= 1) {
      return PasswordStrength.weak;
    } else if (strength <= 3) {
      return PasswordStrength.fair;
    } else if (strength <= 5) {
      return PasswordStrength.good;
    } else {
      return PasswordStrength.strong;
    }
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    final strength = validatePasswordStrength(value);
    if (strength == PasswordStrength.weak) {
      return 'Le mot de passe est trop faible';
    }
    return null;
  }

  // Name validation (letters only, accents allowed)
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    // Allow letters, spaces, hyphens, and accented characters
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$");
    if (!nameRegex.hasMatch(value)) {
      return '$fieldName ne peut contenir que des lettres';
    }
    if (value.length < 2) {
      return '$fieldName doit contenir au moins 2 caractères';
    }
    return null;
  }

  static bool isNameValid(String? value) {
    if (value == null || value.isEmpty) return false;
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$");
    return nameRegex.hasMatch(value) && value.length >= 2;
  }

  // Username validation (letters, numbers, underscore, hyphen)
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom d\'utilisateur est requis';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_\-]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Le nom d\'utilisateur ne peut contenir que des lettres, des chiffres, _ et -';
    }
    if (value.length < 3) {
      return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
    }
    if (value.length > 20) {
      return 'Le nom d\'utilisateur doit contenir au maximum 20 caractères';
    }
    return null;
  }

  static bool isUsernameValid(String? value) {
    if (value == null || value.isEmpty) return false;
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_\-]+$');
    return usernameRegex.hasMatch(value) && value.length >= 3 && value.length <= 20;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  static bool doesPasswordMatch(String? confirmPassword, String password) {
    if (confirmPassword == null || confirmPassword.isEmpty) return false;
    return confirmPassword == password;
  }
}

enum PasswordStrength {
  empty,
  weak,
  fair,
  good,
  strong,
}

extension PasswordStrengthExtension on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.empty:
        return 'Pas de mot de passe';
      case PasswordStrength.weak:
        return 'Faible';
      case PasswordStrength.fair:
        return 'Moyen';
      case PasswordStrength.good:
        return 'Bon';
      case PasswordStrength.strong:
        return 'Fort';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.empty:
        return Colors.grey;
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.amber;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  int get percentage {
    switch (this) {
      case PasswordStrength.empty:
        return 0;
      case PasswordStrength.weak:
        return 25;
      case PasswordStrength.fair:
        return 50;
      case PasswordStrength.good:
        return 75;
      case PasswordStrength.strong:
        return 100;
    }
  }
}
