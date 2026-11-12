import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_theme.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/models/accounting.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/screens/ledger_screens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<_Clubs> open(WidgetTester tester) async {
    final clubs = _Clubs();
    final deps = MoaDependencies(auth: _Auth(), clubs: clubs);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => LedgerDetailScreen(
                    deps: deps,
                    args: const LedgerEntryArgs(clubId: 'club', entryId: 'e1'),
                  ),
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return clubs;
  }

  testWidgets('삭제를 누르면 확인창을 띄우고, 취소하면 지우지 않는다 (#32)', (tester) async {
    final clubs = await open(tester);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('이 거래를 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(clubs.deleted, 0);
    expect(find.text('거래 상세'), findsOneWidget);
  });

  testWidgets('확인창에서 삭제를 고르면 거래를 지우고 닫는다 (#32)', (tester) async {
    final clubs = await open(tester);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('삭제')));
    await tester.pumpAndSettle();
    expect(clubs.deleted, 1);
    expect(find.text('열기'), findsOneWidget);
  });
}

class _Auth implements AuthGateway {
  @override
  String? get currentUid => 'owner';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Clubs implements ClubGateway {
  int deleted = 0;

  static const club = Club(
    id: 'club',
    name: '모해 러닝크루',
    tagline: '',
    category: '운동',
    joinPolicy: 'approval',
    ownerId: 'owner',
    ownerName: '김병진',
    memberCount: 1,
    balance: 0,
    duesPaidCount: 0,
    duesTotalCount: 0,
    duesMonthLabel: '11월',
  );

  @override
  Future<AccountingData> loadAccounting({required String uid, required String clubId}) async {
    return AccountingData(
      club: club,
      role: 'owner',
      userId: 'owner',
      userName: '김병진',
      members: const [],
      rounds: const [],
      currentPayments: const [],
      myPayments: const [],
      entries: [
        LedgerEntry(
          id: 'e1',
          kind: 'income',
          amount: 1000,
          title: '테스트 회비 · 김병진',
          occurredAt: DateTime(2026, 11, 13),
          category: '활동비',
          memo: '회비 입금 확인',
          actorId: 'owner',
          actorName: '김병진',
        ),
      ],
      notices: const [],
    );
  }

  @override
  Future<void> deleteLedgerEntry({required String clubId, required String entryId}) async {
    deleted++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
