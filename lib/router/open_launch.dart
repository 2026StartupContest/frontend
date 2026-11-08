import 'package:flutter/material.dart';
import 'package:flutter_proj/data/gateways.dart';

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

class MoaDependencies {
  const MoaDependencies({required this.auth, required this.clubs});

  final AuthGateway auth;
  final ClubGateway clubs;
}
