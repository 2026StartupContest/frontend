// 시연 전 QA에서 찾은 버그를 iOS 시뮬레이터에서 재현하고 화면을 캡처합니다.
// 실행: QA_SHOT_DIR=~/Desktop/moa_qa_screenshots fvm flutter drive \
//   --driver=test_driver/integration_test.dart \
//   --target=integration_test/qa_repro_test.dart -d <simulator>
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_theme.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_router.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/settlement_chrome.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pump();
    try {
      await binding.takeScreenshot(name);
    } catch (error) {
      // flutter test(기기 없이)로 돌릴 때는 캡처를 건너뜁니다.
      debugPrint('screenshot skipped: $name');
    }
  }

  testWidgets('02 정산 금액을 다시 열고 그대로 입력하면 0원', (tester) async {
    int? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            appBar: AppBar(title: const Text('QA: N차 정산 총 결제 금액')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('저장돼 있던 1차 금액: 120,000원'),
                  const SizedBox(height: 12),
                  Text(
                    result == null ? '아직 입력 전' : '입력 후 저장되는 금액: $result원',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      final next = await askSettlementAmount(
                        context,
                        title: '총 결제 금액',
                        initial: 120000,
                      );
                      setState(() => result = next);
                    },
                    child: const Text('금액 다시 열기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('금액 다시 열기'));
    await tester.pumpAndSettle();
    await shot(tester, '02a_settlement_amount_sheet');
    await tester.tap(find.text('입력하기'));
    await tester.pumpAndSettle();
    await shot(tester, '02b_settlement_amount_became_zero');
    expect(result, 0, reason: '버그가 고쳐졌다면 120000이 나와야 합니다.');
  });

  testWidgets('03 다른 화면에서 홈 탭으로 돌아와도 홈이 갱신되지 않음', (tester) async {
    final clubs = _QaClubs();
    await _openRoute(tester, clubs, AppRoutes.home, const HomeArgs('club'));
    await tester.ensureVisible(find.text('차곡차곡, 최근 기록'));
    await tester.pumpAndSettle();
    await shot(tester, '03a_home_before');
    final before = clubs.homeLoads;

    // 회계 화면에서 회비 입금을 확인한 것과 같은 상황: 서버에는 새 기록이 생겼습니다.
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('회계 (입금 확인 완료)')),
          body: Center(
            child: FilledButton(
              onPressed: () => goClubHome(context, 'club'),
              child: const Text('하단 홈 탭 누르기'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    clubs.activities.add(
      const ActivityItem(
        id: 'new',
        title: '11월 회비 입금 확인',
        subtitle: '김지우 · 방금',
        amount: 10000,
        amountNote: '회비',
      ),
    );
    await tester.tap(find.text('하단 홈 탭 누르기'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('차곡차곡, 최근 기록'));
    await tester.pumpAndSettle();
    await shot(tester, '03b_home_after_go_home_still_stale');
    debugPrint('QA03 loadHome calls before=$before after=${clubs.homeLoads}');
    expect(clubs.homeLoads, before, reason: '버그가 고쳐졌다면 홈을 다시 불러와야 합니다.');
  });

  testWidgets('04 홈 로딩이 네트워크 오류로 실패하면 막다른 화면', (tester) async {
    final clubs = _QaClubs()..failHome = true;
    await _openRoute(tester, clubs, AppRoutes.home, const HomeArgs('club'));
    await shot(tester, '04_home_network_error_dead_end');
    expect(find.text('다시 시도'), findsNothing);
  });

  testWidgets('01 모임 만들기에서 참가비 저장 시 빨간 화면', (tester) async {
    await _openRoute(
      tester,
      _QaClubs(),
      AppRoutes.meetingEdit,
      const MeetingArgs(clubId: 'club', role: 'owner'),
    );
    await tester.scrollUntilVisible(
      find.text('참가비 받기'),
      200,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    await _settle(tester);
    await tester.tap(find.text('참가비 받기'));
    await _settle(tester);
    await tester.tap(find.text('1인 금액'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, '15000');
    await shot(tester, '01a_fee_dialog_before_save');
    await tester.tap(find.text('저장'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    await shot(tester, '01b_fee_save_red_screen');
    final error = tester.takeException();
    debugPrint('QA01 error: $error');
    // 버그로 위젯 트리가 깨진 상태라, 다음 테스트를 위해 화면을 걷어 내고 남은 예외를 비웁니다.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      tester.takeException();
    }
    await tester.pumpWidget(const SizedBox());
    tester.takeException();
    expect(error, isNotNull, reason: '버그가 고쳐졌다면 예외가 없어야 합니다.');
  });
}

/// 끝없이 프레임을 요청하는 화면에서도 멈추지 않도록 정해진 시간만 흘려보냅니다.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openRoute(
  WidgetTester tester,
  ClubGateway clubs,
  String route,
  Object arguments,
) async {
  final deps = MoaDependencies(auth: _QaAuth(), clubs: clubs);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(settings, deps),
      onGenerateInitialRoutes: (_) => [
        AppRouter.onGenerateRoute(
          RouteSettings(name: route, arguments: arguments),
          deps,
        ),
      ],
    ),
  );
  await _settle(tester);
}

class _QaAuth implements AuthGateway {
  @override
  String? get currentUid => 'owner';

  @override
  String? get currentDisplayName => '김병진';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QaClubs implements ClubGateway {
  int homeLoads = 0;
  bool failHome = false;
  final activities = <ActivityItem>[];

  static const club = Club(
    id: 'club',
    name: '모해 러닝크루',
    tagline: '같이 달리면 더 멀리',
    category: '운동',
    joinPolicy: 'approval',
    ownerId: 'owner',
    ownerName: '김병진',
    memberCount: 12,
    balance: 0,
    duesPaidCount: 0,
    duesTotalCount: 0,
    duesMonthLabel: '11월',
  );

  @override
  Future<HomeData> loadHome({required String uid, required String clubId}) async {
    homeLoads++;
    if (failHome) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'The service is currently unavailable. This is a most likely a transient condition and may be corrected by retrying with a backoff.',
      );
    }
    return HomeData(
      user: const AppUser(id: 'owner', name: '김병진', email: 'owner@example.test', activityAlerts: true),
      club: club,
      clubs: const [club],
      events: const [],
      activities: List.of(activities),
      notices: const [],
      tasks: const [],
      role: 'owner',
      options: const [ClubOption(club: club, role: 'owner', status: 'active', primary: true)],
      primaryClubId: 'club',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
