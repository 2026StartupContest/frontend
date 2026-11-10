import 'package:flutter/material.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/screens/accounting_screen.dart';
import 'package:flutter_proj/screens/attendance_done_screen.dart';
import 'package:flutter_proj/screens/attendance_home_screen.dart';
import 'package:flutter_proj/screens/attendance_manage_screen.dart';
import 'package:flutter_proj/screens/attendance_qr_screen.dart';
import 'package:flutter_proj/screens/attendance_rates_screen.dart';
import 'package:flutter_proj/screens/attendance_roster_screen.dart';
import 'package:flutter_proj/screens/attendance_scan_screen.dart';
import 'package:flutter_proj/screens/club_settings_screen.dart';
import 'package:flutter_proj/screens/create_club_screen.dart';
import 'package:flutter_proj/screens/dues_settings_screen.dart';
import 'package:flutter_proj/screens/home_screen.dart';
import 'package:flutter_proj/screens/join_inbox_screen.dart';
import 'package:flutter_proj/screens/meeting_attendees_screen.dart';
import 'package:flutter_proj/screens/meeting_detail_screen.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/screens/meeting_form_screen.dart';
import 'package:flutter_proj/screens/place_confirm_screen.dart';
import 'package:flutter_proj/screens/place_detail_screen.dart';
import 'package:flutter_proj/screens/place_list_screen.dart';
import 'package:flutter_proj/screens/place_menu_screen.dart';
import 'package:flutter_proj/screens/place_paid_screen.dart';
import 'package:flutter_proj/screens/place_pay_screen.dart';
import 'package:flutter_proj/screens/place_reserve_screen.dart';
import 'package:flutter_proj/screens/place_reserved_screen.dart';
import 'package:flutter_proj/screens/place_search_screen.dart';
import 'package:flutter_proj/screens/meetings_screen.dart';
import 'package:flutter_proj/screens/my_page_screen.dart';
import 'package:flutter_proj/screens/member_roles_screen.dart';
import 'package:flutter_proj/screens/invite_screen.dart';
import 'package:flutter_proj/screens/join_code_screen.dart';
import 'package:flutter_proj/screens/join_pending_screen.dart';
import 'package:flutter_proj/screens/join_request_screen.dart';
import 'package:flutter_proj/screens/ledger_screens.dart';
import 'package:flutter_proj/screens/login_screen.dart';
import 'package:flutter_proj/screens/no_club_screen.dart';
import 'package:flutter_proj/screens/signup_done_screen.dart';
import 'package:flutter_proj/screens/settlement_attendees_screen.dart';
import 'package:flutter_proj/screens/settlement_create_screen.dart';
import 'package:flutter_proj/screens/settlement_detail_screen.dart';
import 'package:flutter_proj/screens/settlement_list_screen.dart';
import 'package:flutter_proj/screens/settlement_members_screen.dart';
import 'package:flutter_proj/screens/settlement_rounds_screen.dart';
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
      AppRoutes.attendance => AttendanceHomeScreen(
        deps: deps,
        clubId: (settings.arguments! as ClubArgs).clubId,
      ),
      AppRoutes.attendanceRates => AttendanceRatesScreen(
        deps: deps,
        clubId: (settings.arguments! as ClubArgs).clubId,
      ),
      AppRoutes.attendanceScan => AttendanceScanScreen(
        deps: deps,
        args: settings.arguments! as MeetingArgs,
      ),
      AppRoutes.attendanceDone => AttendanceDoneScreen(
        deps: deps,
        args: settings.arguments! as AttendanceDoneArgs,
      ),
      AppRoutes.attendanceManage => AttendanceManageScreen(
        deps: deps,
        args: settings.arguments! as MeetingArgs,
      ),
      AppRoutes.attendanceQr => AttendanceQrScreen(
        deps: deps,
        args: settings.arguments! as MeetingArgs,
      ),
      AppRoutes.attendanceRoster => AttendanceRosterScreen(
        deps: deps,
        args: settings.arguments! as MeetingArgs,
      ),
      AppRoutes.places => PlaceSearchScreen(
        clubId: (settings.arguments! as PlaceFlowArgs).clubId,
      ),
      AppRoutes.placeMenu => PlaceMenuScreen(
        args: settings.arguments! as PlaceFlowArgs,
      ),
      AppRoutes.placeReserve => PlaceReserveScreen(
        args: settings.arguments! as PlaceFlowArgs,
      ),
      AppRoutes.placeConfirm => PlaceConfirmScreen(
        args: settings.arguments! as PlaceFlowArgs,
      ),
      AppRoutes.placeReserved => PlaceReservedScreen(
        args: settings.arguments! as PlaceFlowArgs,
      ),
      AppRoutes.reservations => PlaceListScreen(
        args: settings.arguments! as PlaceFlowArgs,
      ),
      AppRoutes.reservationDetail => PlaceDetailScreen(
        args: settings.arguments! as PlaceFlowArgs,
      ),
      AppRoutes.reservationPay => PlacePayScreen(
        args: settings.arguments! as PlaceFlowArgs,
      ),
      AppRoutes.reservationPaid => PlacePaidScreen(
        args: settings.arguments! as PlaceFlowArgs,
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
      AppRoutes.accounting => AccountingScreen(
        deps: deps,
        args: settings.arguments! as AccountingArgs,
      ),
      AppRoutes.duesSettings => DuesSettingsScreen(
        deps: deps,
        clubId: (settings.arguments! as ClubArgs).clubId,
      ),
      AppRoutes.ledgerAll => LedgerTransactionsScreen(
        deps: deps,
        clubId: (settings.arguments! as ClubArgs).clubId,
      ),
      AppRoutes.ledgerEntry => LedgerEntryScreen(
        deps: deps,
        args: settings.arguments! as LedgerEntryArgs,
      ),
      AppRoutes.ledgerDetail => LedgerDetailScreen(
        deps: deps,
        args: settings.arguments! as LedgerEntryArgs,
      ),
      AppRoutes.settlements => SettlementListScreen(
        deps: deps,
        clubId: (settings.arguments! as ClubArgs).clubId,
      ),
      AppRoutes.settlementCreate => SettlementCreateScreen(
        deps: deps,
        args: settings.arguments! as SettlementArgs,
      ),
      AppRoutes.settlementRounds => SettlementRoundsScreen(
        deps: deps,
        args: settings.arguments! as SettlementArgs,
      ),
      AppRoutes.settlementAttendees => SettlementAttendeesScreen(
        deps: deps,
        args: settings.arguments! as SettlementArgs,
      ),
      AppRoutes.settlementDetail => SettlementDetailScreen(
        deps: deps,
        args: settings.arguments! as SettlementArgs,
      ),
      AppRoutes.settlementMembers => SettlementMembersScreen(
        deps: deps,
        args: settings.arguments! as SettlementArgs,
      ),
      _ => LoginScreen(deps: deps),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}
