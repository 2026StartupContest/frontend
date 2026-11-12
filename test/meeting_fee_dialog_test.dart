import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_theme.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/router/app_router.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('참가비 1인 금액을 저장해도 에러 없이 닫히고 금액이 반영된다 (#17)', (tester) async {
    final deps = MoaDependencies(auth: _Auth(), clubs: _Clubs());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        onGenerateRoute: (settings) => AppRouter.onGenerateRoute(settings, deps),
        onGenerateInitialRoutes: (_) => [
          AppRouter.onGenerateRoute(
            const RouteSettings(
              name: AppRoutes.meetingEdit,
              arguments: MeetingArgs(clubId: 'club', role: 'owner'),
            ),
            deps,
          ),
        ],
      ),
    );
    await _settle(tester);
    await tester.scrollUntilVisible(
      find.text('참가비 받기'),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    await _settle(tester);
    await tester.tap(find.text('참가비 받기'));
    await _settle(tester);
    await tester.tap(find.text('1인 금액'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, '15000');
    await tester.tap(find.text('저장'));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('15,000'), findsWidgets);
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
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
