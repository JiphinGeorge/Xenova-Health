import '../constants/app_constants.dart';

/// Input validators for forms across the application.
abstract final class Validators {
  /// Validates an email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validates a password.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password is too long';
    }
    return null;
  }

  /// Validates password confirmation.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates a name field.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < AppConstants.minNameLength) {
      return 'Name must be at least ${AppConstants.minNameLength} characters';
    }
    if (value.trim().length > AppConstants.maxNameLength) {
      return 'Name is too long';
    }
    return null;
  }

  /// Validates age.
  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value.trim());
    if (age == null) return 'Please enter a valid age';
    if (age < AppConstants.minAge)
      return 'Must be at least ${AppConstants.minAge} years old';
    if (age > AppConstants.maxAge) return 'Please enter a valid age';
    return null;
  }

  /// Validates weight in kg.
  static String? weight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Weight is required';
    }
    final weight = double.tryParse(value.trim());
    if (weight == null) return 'Please enter a valid weight';
    if (weight < AppConstants.minWeight) return 'Weight too low';
    if (weight > AppConstants.maxWeight) return 'Weight too high';
    return null;
  }

  /// Validates height in cm.
  static String? height(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Height is required';
    }
    final height = double.tryParse(value.trim());
    if (height == null) return 'Please enter a valid height';
    if (height < AppConstants.minHeight) return 'Height too low';
    if (height > AppConstants.maxHeight) return 'Height too high';
    return null;
  }

  /// Validates a required field.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates calories (positive number).
  static String? calories(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Calories are required';
    }
    final cal = double.tryParse(value.trim());
    if (cal == null || cal < 0) return 'Please enter a valid number';
    if (cal > 10000) return 'Value is too high';
    return null;
  }

  /// Validates a macro nutrient value (protein/fat/carbs in grams).
  static String? macroNutrient(String? value, String nutrientName) {
    if (value == null || value.trim().isEmpty) {
      return '$nutrientName is required';
    }
    final val = double.tryParse(value.trim());
    if (val == null || val < 0) return 'Please enter a valid number';
    if (val > 1000) return 'Value is too high';
    return null;
  }
}
