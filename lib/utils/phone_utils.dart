import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PhoneUtils {
  static MaskTextInputFormatter get maskFormatter => MaskTextInputFormatter(
    mask: '+998 ## ### ## ##', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  static MaskTextInputFormatter get uzPhoneMaskFormatter => MaskTextInputFormatter(
    mask: '## ### ## ##',
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  static String normalize(String phone) {
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 9) {
      return '+998$digits';
    }
    return '+$digits';
  }

  /// Formats any phone number nicely as: +998 99 999 99 99 (or 99 999 99 99)
  static String formatPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998') && digits.length >= 12) {
      final sub = digits.substring(3, 12);
      return '+998 ${sub.substring(0, 2)} ${sub.substring(2, 5)} ${sub.substring(5, 7)} ${sub.substring(7, 9)}';
    } else if (digits.length == 9) {
      return '+998 ${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';
    }
    return phone;
  }
}
