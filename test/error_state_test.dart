import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_theme.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_router.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('에러 문구는 Firebase 원문 대신 한국어 안내로 바꾼다 (#20)', () {
    FirebaseException fire(String code) =>
        FirebaseException(plugin: 'cloud_firestore', code: code, message: 'The service is currently unavailable.');
    expect(friendlyErrorMessage(fire('unavailable')), '네트워크 연결을 확인해 주세요.');
    expect(friendlyErrorMessage(fire('network-request-failed')), '네트워크 연결을 확인해 주세요.');
    expect(friendlyErrorMessage(fire('deadline-exceeded')), '네트워크 연결을 확인해 주세요.');
    expect(friendlyErrorMessage(fire('permission-denied')), '권한이 없어요. 운영진에게 확인해 주세요.');
    expect(friendlyErrorMessage(fire('internal')), '잠시 후 다시 시도해 주세요.');
    expect(friendlyErrorMessage(StateError('동아리를 찾을 수 없어요.')), '동아리를 찾을 수 없어요.');
    expect(friendlyErrorMessage(Exception('boom')), '잠시 후 다시 시도해 주세요.');
  });

  testWidgets('홈 로딩이 실패하면 안내와 다시 시도를 보여 주고, 다시 시도하면 홈이 뜬다 (#20)', (tester) async {
    final clubs = _Clubs()..failures = 1;
    final deps = MoaDependencies(auth: _Auth(), clubs: clubs);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        onGenerateRoute: (settings) => AppRouter.onGenerateRoute(settings, deps),
        onGenerateInitialRoutes: (_) => [
          AppRouter.onGenerateRoute(
            const RouteSettings(name: AppRoutes.home, arguments: HomeArgs('club')),
            deps,
          ),
        ],
      ),
    );
    await _settle(tester);
    expect(find.text('네트워크 연결을 확인해 주세요.'), findsOneWidget);
    expect(find.textContaining('cloud_firestore'), findsNothing);
    expect(find.text('다시 시도'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await _settle(tester);
    expect(clubs.homeLoads, 2);
    expect(find.text('다시 시도'), findsNothing);
    expect(find.text('모해 러닝크루'), findsWidgets);
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
  int failures = 0;

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
    if (failures > 0) {
      failures--;
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'The service is currently unavailable.',
      );
    }
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
