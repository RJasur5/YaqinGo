import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ' '; // Change this to '.' for other locales

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Short-circuit if the new value is empty
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Handle "deletion" of separator character
    String oldValueText = oldValue.text.replaceAll(separator, '');
    String newValueText = newValue.text.replaceAll(separator, '');

    if (oldValue.text.endsWith(separator) &&
        oldValue.text.length == newValue.text.length + 1) {
      newValueText = newValueText.substring(0, newValueText.length - 1);
    }

    // Only process if the new value contains only digits
    if (newValueText != '' && int.tryParse(newValueText) == null) {
      return oldValue;
    }

    final int selectionIndexFromRight =
        newValue.text.length - newValue.selection.end;

    final f = NumberFormat('#,###');
    String newString = '';
    if (newValueText.isNotEmpty) {
      newString = f.format(int.parse(newValueText)).replaceAll(',', separator);
    }

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(
        offset: newString.length - selectionIndexFromRight,
      ),
    );
  }
}

class PriceFormatter {
  static String format(dynamic price) {
    if (price == null) return '0';
    double n = (price is num) ? price.toDouble() : (double.tryParse(price.toString()) ?? 0.0);
    final f = NumberFormat('#,###');
    return f.format(n.toInt()).replaceAll(',', ' ');
  }

  static String formatPhone(String phone) {
    // Strip non-digits
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // If it's the expected 12 digits (998 + 9 digits)
    if (digits.length == 12 && digits.startsWith('998')) {
      return '+998 (${digits.substring(3, 5)}) ${digits.substring(5, 8)}-${digits.substring(8, 10)}-${digits.substring(10, 12)}';
    }
    
    // Fallback if it's just 9 digits (no 998 prefix)
    if (digits.length == 9) {
      return '+998 (${digits.substring(0, 2)}) ${digits.substring(2, 5)}-${digits.substring(5, 7)}-${digits.substring(7, 9)}';
    }

    return phone; // Return original if it doesn't match expected patterns
  }
}

extension StringExtension on String {
  String capitalizeWords() {
    if (trim().isEmpty) return '';
    return split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
