import 'package:flutter/material.dart';
import 'package:flutter_proj/core/won_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _value(String text, [int? cursor]) =>
    TextEditingValue(text: text, selection: TextSelection.collapsed(offset: cursor ?? text.length));

void main() {
  const formatter = WonInputFormatter();
  TextEditingValue type(TextEditingValue old, String next, [int? cursor]) =>
      formatter.formatEditUpdate(old, _value(next, cursor));

  test('30,000을 한 글자씩 지우고 1000을 입력하면 1,000이 된다 (#31)', () {
    var value = _value('30,000');
    // 백스페이스: 커서 앞 글자를 하나씩 지운다.
    while (value.text.isNotEmpty) {
      final cut = value.selection.baseOffset;
      final next = value.text.substring(0, cut - 1) + value.text.substring(cut);
      value = type(value, next, cut - 1);
    }
    expect(value.text, '');
    for (final digit in ['1', '0', '0', '0']) {
      final cut = value.selection.baseOffset;
      value = type(value, value.text.substring(0, cut) + digit + value.text.substring(cut), cut + 1);
    }
    expect(value.text, '1,000');
    expect(value.selection.baseOffset, 5);
  });

  test('쉼표를 넣고 숫자가 아닌 글자와 앞자리 0은 버린다', () {
    expect(type(_value(''), '1234567').text, '1,234,567');
    expect(type(_value(''), '00120').text, '120');
    expect(type(_value(''), '12a3원').text, '123');
    expect(type(_value('1'), '').text, '');
  });

  test('중간을 고쳐도 커서가 같은 숫자 뒤에 머문다', () {
    // 30,000 에서 3 뒤(커서 1)에 5를 넣으면 350,000, 커서는 5 뒤.
    final value = type(_value('30,000'), '350,000', 2);
    expect(value.text, '350,000');
    expect(value.text.substring(0, value.selection.baseOffset), '35');
  });

  testWidgets('금액 칸을 비우고 1000을 입력하면 1,000으로 보인다 (#31)', (tester) async {
    final controller = TextEditingController(text: '30,000');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: const [WonInputFormatter()],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '');
    await tester.enterText(find.byType(TextField), '1000');
    await tester.pump();
    expect(controller.text, '1,000');
    expect(find.text('1,000'), findsOneWidget);
  });
}
