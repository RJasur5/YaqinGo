import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PhoneUtils {
  static MaskTextInputFormatter get maskFormatter => MaskTextInputFormatter(
    mask: '+998 (##) ###-##-##', 
    filter: { "#": RegExp(r'[0-9]') },
    type: MaskAutoCompletionType.lazy,
  );

  static String normalize(String phone) {
    return '+' + phone.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
