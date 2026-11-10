import 'package:flutter/material.dart';
import 'package:flutter_proj/core/accounting.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/router/app_routes.dart';

Future<void> openLaunch(BuildContext context, MoaDependencies deps) async {
  final uid = deps.auth.currentUid;
  if (uid == null) return;
  final launch = await deps.clubs.launchFor(uid);
  if (!context.mounted) return;
  await Navigator.pushNamedAndRemoveUntil(
    context,
    launch.route,
    (_) => false,
    arguments: launch.arguments,
  );
}

/// 쌓인 화면을 걷어 내고 동아리 홈으로 돌아갑니다.
void goClubHome(BuildContext context, String clubId) {
  var foundHome = false;
  Navigator.popUntil(context, (route) {
    final isHome = route.settings.name == AppRoutes.home;
    if (isHome) foundHome = true;
    return isHome || route.isFirst;
  });
  if (!foundHome && context.mounted) {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.home,
      arguments: HomeArgs(clubId),
    );
  }
}

void openAccounting(
  BuildContext context,
  String clubId, {
  String segment = AccountingSegment.dues,
}) {
  Navigator.pushNamed(
    context,
    AppRoutes.accounting,
    arguments: AccountingArgs(clubId, segment),
  );
}

class MoaDependencies {
  const MoaDependencies({required this.auth, required this.clubs});

  final AuthGateway auth;
  final ClubGateway clubs;
}
