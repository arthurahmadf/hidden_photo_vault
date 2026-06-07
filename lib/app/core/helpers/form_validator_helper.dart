abstract class ValidatorHelper {
  /// **1️⃣ Required Field Validator**
  /// Ensures the input is not empty.
  static String? mustBeFilled(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Wajib diisi...";
    }
    return null;
  }

  /// **2️⃣ Email Validator**
  /// Checks if the input is a valid email format.
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return "Email is required";
    }
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegex.hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }

  /// **3️⃣ Minimum Length Validator**
  /// Ensures the input meets a minimum length.
  static String? minLength(String? value, int min) {
    if (value == null || value.length < min) {
      return "Must be at least $min characters";
    }
    return null;
  }

  /// **4️⃣ Numeric Validation**
  /// Ensures the input is a valid number.
  static String? isNumeric(String? value) {
    if (value == null || value.isEmpty) {
      return "Wajib diisi...";
    }
    if (double.tryParse(value) == null) {
      return "Hanya angka...";
    }
    return null;
  }
}
