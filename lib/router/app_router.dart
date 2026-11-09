import 'package:flutter/material.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/screens/club_settings_screen.dart';
import 'package:flutter_proj/screens/create_club_screen.dart';
import 'package:flutter_proj/screens/home_screen.dart';
import 'package:flutter_proj/screens/join_inbox_screen.dart';
import 'package:flutter_proj/screens/meeting_attendees_screen.dart';
import 'package:flutter_proj/screens/meeting_detail_screen.dart';
import 'package:flutter_proj/screens/meeting_form_screen.dart';
import 'package:flutter_proj/screens/meetings_screen.dart';
import 'package:flutter_proj/screens/my_page_screen.dart';
import 'package:flutter_proj/screens/member_roles_screen.dart';
import 'package:flutter_proj/screens/invite_screen.dart';
import 'package:flutter_proj/screens/join_code_screen.dart';
import 'package:flutter_proj/screens/join_pending_screen.dart';
import 'package:flutter_proj/screens/join_request_screen.dart';
import 'package:flutter_proj/screens/login_screen.dart';
import 'package:flutter_proj/screens/no_club_screen.dart';
import 'package:flutter_proj/screens/signup_done_screen.dart';
import 'package:flutter_proj/screens/signup_screen.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    MoaDependencies deps,
  ) {
    final page = switch (settings.name) {
      AppRoutes.signup => SignupScreen(
        deps: deps,
        mode: settings.arguments is SignupMode
            ? settings.arguments! as SignupMode
            : SignupMode.create,
      ),
      AppRoutes.signupDone => SignupDoneScreen(
        deps: deps,
        args: settings.arguments! as SignupDoneArgs,
      ),
      AppRoutes.noClub => NoClubScreen(deps: deps),
      AppRoutes.createClub => CreateClubScreen(deps: deps),
      AppRoutes.invite => InviteScreen(
        deps: deps,
        created: settings.arguments! as CreatedClub,
      ),
      AppRoutes.join => JoinCodeScreen(deps: deps),
      AppRoutes.joinRequest => JoinRequestScreen(
        deps: deps,
        club: settings.arguments! as Club,
      ),
      AppRoutes.joinPending => JoinPendingScreen(
        deps: deps,
        clubId: (settings.arguments! as ClubArgs).clubId,
      ),
      AppRoutes.home => HomeScreen(
        deps: deps,
        clubId: (settings.arguments! as HomeArgs).clubId,
      ),
      AppRoutes.myPage => MyPageScreen(
        deps: deps,
        clubId: (settings.arguments! as ClubArgs).clubId,
      ),
      AppRoutes.meetings => MeetingsScreen(
        deps: deps,
        clubId: (settings.arguments! as ClubArgs).clubId,
      ),
      AppRoutes.meetingDetail => MeetingDetailScreen(
        deps: deps,
        args: settings.arguments! as MeetingArgs,
      ),
      AppRoutes.meetingEdit => MeetingFormScreen(
        deps: deps,
        args: settings.arguments! as MeetingArgs,
      ),
      AppRoutes.meetingAttendees => MeetingAttendeesScreen(
        deps: deps,
        args: settings.arguments! as MeetingArgs,
      ),
      AppRoutes.clubSettings => ClubSettingsScreen(
        deps: deps,
        clubId: (settings.arguments! as ClubArgs).clubId,
      ),
      AppRoutes.memberRoles => MemberRolesScreen(
        deps: deps,
        clubId: (settings.arguments! as ClubArgs).clubId,
      ),
      AppRoutes.joinInbox => JoinInboxScreen(
        deps: deps,
        clubId: (settings.arguments! as ClubArgs).clubId,
      ),
      AppRoutes.scan => const QrScanScreen(),
      _ => LoginScreen(deps: deps),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}
