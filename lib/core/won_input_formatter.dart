import 'package:flutter/services.dart';
import 'package:flutter_proj/core/format.dart';

/// 금액 입력칸에서 숫자만 남기고 천 단위 쉼표를 넣습니다(#31).
///
/// `onChanged`에서 controller 값을 바꾸면 iOS 키보드가 기억하는 글자와 칸의 값이
/// 어긋나 숫자가 꼬일 수 있어서, 입력 단계에서 포맷하고 커서 위치도 보존합니다.
class WonInputFormatter extends TextInputFormatter {
  const WonInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(selection: TextSelection.collapsed(offset: 0));
    }
    final text = formatGrouped(int.parse(digits));

    // 커서 앞에 있던 숫자 개수만큼 지난 위치에 커서를 둡니다.
    final cursor = newValue.selection.baseOffset.clamp(0, raw.length);
    final digitsBefore = raw
        .substring(0, cursor)
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length
        .clamp(0, digits.length);
    var offset = 0;
    var seen = 0;
    while (offset < text.length && seen < digitsBefore) {
      if (RegExp(r'[0-9]').hasMatch(text[offset])) seen++;
      offset++;
    }
    if (digitsBefore == digits.length) offset = text.length;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
