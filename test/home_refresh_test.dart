import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_theme.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_router.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('홈에서 연 화면에서 goClubHome으로 돌아오면 홈을 다시 불러온다 (#19)', (tester) async {
    final clubs = _Clubs();
    final deps = MoaDependencies(auth: _Auth(), clubs: clubs);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        onGenerateRoute: (settings) {
          // 회계·마이페이지 등 실제 화면 대신, 하단 홈 탭처럼 goClubHome만 부르는 화면을 띄웁니다.
          if (settings.name != AppRoutes.home) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => goClubHome(context, 'club'),
                    child: const Text('홈 탭'),
                  ),
                ),
              ),
            );
          }
          return AppRouter.onGenerateRoute(settings, deps);
        },
        onGenerateInitialRoutes: (_) => [
          AppRouter.onGenerateRoute(
            const RouteSettings(name: AppRoutes.home, arguments: HomeArgs('club')),
            deps,
          ),
        ],
      ),
    );
    await _settle(tester);
    expect(clubs.homeLoads, 1);

    for (final label in ['회비 관리', '회계 장부']) {
      final before = clubs.homeLoads;
      await tester.tap(find.text(label));
      await _settle(tester);
      expect(find.text('홈 탭'), findsOneWidget);
      await tester.tap(find.text('홈 탭'));
      await _settle(tester);
      expect(clubs.homeLoads, before + 1, reason: '$label 에서 돌아오면 홈을 다시 불러와야 합니다.');
    }

    for (final tab in ['회계', '마이페이지', '예약']) {
      final before = clubs.homeLoads;
      await tester.tap(find.text(tab).last);
      await _settle(tester);
      await tester.tap(find.text('홈 탭'));
      await _settle(tester);
      expect(clubs.homeLoads, before + 1, reason: '하단 $tab 탭에서 돌아오면 홈을 다시 불러와야 합니다.');
    }
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _Auth implements AuthGateway {
  @override
  String? get currentUid => 'owner';

  @override
  String? get currentDisplayName => '김병진';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Clubs implements ClubGateway {
  int homeLoads = 0;

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
    return const HomeData(
      user: AppUser(id: 'owner', name: '김병진', email: 'owner@example.test', activityAlerts: true),
      club: club,
      clubs: [club],
      events: [],
      activities: [],
      notices: [],
      tasks: [],
      role: 'owner',
      options: [ClubOption(club: club, role: 'owner', status: 'active', primary: true)],
      primaryClubId: 'club',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
