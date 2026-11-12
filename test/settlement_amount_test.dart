import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_theme.dart';
import 'package:flutter_proj/widgets/settlement_chrome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<int?> reopenAndSubmit(WidgetTester tester, {required int initial, String? typed}) async {
    int? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await askSettlementAmount(context, title: '총 결제 금액', initial: initial);
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    if (typed != null) await tester.enterText(find.byType(TextField), typed);
    await tester.tap(find.text('입력하기'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('정산 금액을 다시 열고 그대로 입력하면 기존 금액이 유지된다 (#18)', (tester) async {
    expect(await reopenAndSubmit(tester, initial: 120000), 120000);
  });

  testWidgets('정산 금액을 새로 입력하면 그 금액이 저장된다', (tester) async {
    expect(await reopenAndSubmit(tester, initial: 120000, typed: '85000'), 85000);
  });

  testWidgets('빈 금액은 0원으로 저장된다', (tester) async {
    expect(await reopenAndSubmit(tester, initial: 0), 0);
  });
}
