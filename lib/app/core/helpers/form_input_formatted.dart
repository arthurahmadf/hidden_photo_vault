import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RupiahInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove non-digits
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Format with Rp and thousand separator
    final formatted = _formatter.format(double.parse(digitsOnly));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Helper to get raw numeric value as double
  static double? getRawValue(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.isEmpty ? null : double.parse(cleaned);
  }
}

/// Allows only numbers and a single decimal point.
/// Example:
/// - "123" ✅
/// - "123.45" ✅
/// - "123.45.67" ❌ (rejects second dot)
class NumericDecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Only allow digits and dot
    final filtered = text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Prevent multiple dots
    if ('.'.allMatches(filtered).length > 1) {
      return oldValue;
    }

    return newValue.copyWith(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }

  /// Helper to parse raw string into double
  static double? getRawValue(String text) {
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }
}

/// Phone number formatter
/// Allows only digits and limits length.
///
/// Example:
/// - 08123456789 ✅
/// - +628123456789 ❌ (strips +)
/// - abc0812 ❌
///
/// Optional: customize maxLength
class PhoneInputFormatter extends TextInputFormatter {
  final int maxLength;

  PhoneInputFormatter({
    this.maxLength = 15,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Keep digits only
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit length
    if (digitsOnly.length > maxLength) {
      digitsOnly = digitsOnly.substring(0, maxLength);
    }

    return TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );
  }

  /// Helper
  static String? getRawValue(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.isEmpty ? null : cleaned;
  }
}

/// Age in years formatter
/// Allows only integer numbers.
///
/// Example:
/// - 21 ✅
/// - 5 ✅
/// - 12.5 ❌
/// - abc ❌
class AgeInYearInputFormatter extends TextInputFormatter {
  final int maxAge;

  AgeInYearInputFormatter({
    this.maxAge = 120,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Digits only
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final age = int.tryParse(digitsOnly);

    // Reject impossible age
    if (age == null || age > maxAge) {
      return oldValue;
    }

    return TextEditingValue(
      text: digitsOnly,
      selection: TextSelection.collapsed(offset: digitsOnly.length),
    );
  }

  /// Helper
  static int? getRawValue(String text) {
    return int.tryParse(text);
  }
}
