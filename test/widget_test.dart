import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_theme.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/models/accounting.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/models/settlement.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/screens/login_screen.dart';
import 'package:flutter_proj/widgets/moa_bottom_nav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('하단 네비게이션은 다섯 탭과 선택 상태를 그린다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          bottomNavigationBar: MoaBottomNav(
            selected: MoaTab.home,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('예약'), findsOneWidget);
    expect(find.text('출석'), findsOneWidget);
    expect(find.text('회계'), findsOneWidget);
    expect(find.text('마이페이지'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          bottomNavigationBar: MoaBottomNav(selected: MoaTab.attendance),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('nav-attendance')), findsOneWidget);
  });

  testWidgets('로그인 화면은 이메일 로그인과 구글 시작하기를 보여 준다', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: LoginScreen(
          deps: MoaDependencies(auth: _FakeAuth(), clubs: _FakeClubs()),
        ),
      ),
    );
    expect(find.text('구글로 시작하기'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
  });
}

class _FakeAuth implements AuthGateway {
  @override
  String? get currentDisplayName => null;

  @override
  String? get currentEmail => null;

  @override
  String? get currentUid => null;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> ensureRecentLogin() async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {}
}

class _FakeClubs implements ClubGateway {
  @override
  Future<void> askOwner({
    required String uid,
    required String userName,
    required String clubId,
  }) async {}

  @override
  Future<void> cancelJoin({
    required String uid,
    required String clubId,
  }) async {}

  @override
  Future<CreatedClub> createClub({
    required String ownerId,
    required String ownerName,
    required String name,
    required String tagline,
    required String category,
    required String joinPolicy,
    int? feeAmount,
    ImagePayload? image,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> ensureUser({
    required String id,
    required String name,
    required String email,
    bool activityAlerts = false,
  }) async {}

  @override
  Future<ClubPreview?> findByCode(String code) async => null;

  @override
  Future<AppUser?> getUser(String uid) async => null;

  @override
  Future<ProfileData> loadProfile(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateNickname({
    required String uid,
    required String nickname,
  }) async {}

  @override
  Future<void> updateActivityAlerts({
    required String uid,
    required bool enabled,
  }) async {}

  @override
  Future<void> deleteAccountData(String uid) async {}

  @override
  Future<void> joinImmediately({
    required String uid,
    required String userName,
    required Club club,
  }) async {}

  @override
  Future<LaunchTarget> launchFor(String uid) {
    throw UnimplementedError();
  }

  @override
  Future<HomeData> loadHome({required String uid, required String clubId}) {
    throw UnimplementedError();
  }

  @override
  Future<PendingView> loadPending({
    required String uid,
    required String clubId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markNoticesRead(String clubId) async {}

  @override
  Future<void> requestJoin({
    required String uid,
    required String userName,
    required Club club,
    required String depositName,
    required bool feeReported,
  }) async {}

  @override
  Future<void> approveJoins({
    required String clubId,
    required List<String> userIds,
  }) async {}

  @override
  Future<String?> deleteClub({
    required String uid,
    required String clubId,
  }) async => null;

  @override
  Future<ClubDesk> loadDesk({required String uid, required String clubId}) {
    throw UnimplementedError();
  }

  @override
  Future<String> reissueInvite({required String clubId}) async => '';

  @override
  Future<void> rejectJoins({
    required String clubId,
    required List<String> userIds,
  }) async {}

  @override
  Future<void> removeMember({
    required String clubId,
    required String userId,
  }) async {}

  @override
  Future<void> setMemberRole({
    required String clubId,
    required String userId,
    required String role,
  }) async {}

  @override
  Future<void> setPrimaryClub({
    required String uid,
    required String clubId,
  }) async {}

  @override
  Future<void> transferOwnership({
    required String clubId,
    required String fromUserId,
    required String toUserId,
  }) async {}

  @override
  Future<void> updateClubName({
    required String clubId,
    required String name,
    ImagePayload? image,
  }) async {}

  @override
  Future<void> updateFeeAmount({
    required String clubId,
    required int? feeAmount,
  }) async {}

  @override
  Future<void> updateJoinPolicy({
    required String clubId,
    required String joinPolicy,
  }) async {}

  @override
  Future<void> deleteMeeting({
    required String clubId,
    required String eventId,
  }) async {}

  @override
  Future<ClubEvent> loadEvent({
    required String clubId,
    required String eventId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> saveMeeting({
    required String clubId,
    required ClubEvent event,
    ImagePayload? image,
  }) async => event.id;

  @override
  Future<void> setMeetingAttendees({
    required String clubId,
    required String eventId,
    required List<String> attendeeIds,
  }) async {}

  @override
  Future<void> setMeetingStatus({
    required String clubId,
    required String eventId,
    required String status,
  }) async {}

  @override
  Future<List<ClubEvent>> loadMeetings({required String clubId}) async =>
      const [];

  @override
  Stream<ClubEvent> watchEvent({
    required String clubId,
    required String eventId,
  }) => const Stream.empty();

  @override
  Stream<List<AttendanceRecord>> watchAttendance({
    required String clubId,
    required String eventId,
  }) => const Stream.empty();

  @override
  Future<Map<String, List<AttendanceRecord>>> loadAttendanceRecords({
    required String clubId,
    required List<String> eventIds,
  }) async => const {};

  @override
  Stream<QrSession?> watchAttendanceQr({
    required String clubId,
    required String eventId,
  }) => const Stream.empty();

  @override
  Future<QrSession> rotateAttendanceQr({
    required String clubId,
    required String eventId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> closeAttendance({
    required String clubId,
    required String eventId,
  }) async {}

  @override
  Future<CheckInResult> checkInWithQr({
    required String uid,
    required String raw,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markAttendanceManually({
    required String clubId,
    required String eventId,
    required String userId,
    required String userName,
    required String actorId,
    required String actorName,
    String? reason,
  }) async {}

  @override
  Future<AccountingData> loadAccounting({
    required String uid,
    required String clubId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> registerDues({
    required String clubId,
    required String actorId,
    required String title,
    required int amount,
    required DateTime dueAt,
    required String repeat,
    required bool allMembers,
    required List<DuesTarget> targets,
  }) async {}

  @override
  Future<void> reportDuesPayment({
    required String clubId,
    required String duesId,
    required String userId,
    required String depositName,
  }) async {}

  @override
  Future<void> confirmDuesPayment({
    required String clubId,
    required String duesId,
    required String userId,
    required String actorId,
    required String actorName,
    required String ledgerTitle,
    required int amount,
  }) async {}

  @override
  Future<void> remindUnpaidDues({
    required String clubId,
    required String actorId,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> saveLedgerEntry({
    required String clubId,
    required String actorId,
    required String actorName,
    String? entryId,
    required String kind,
    required int amount,
    required String title,
    required DateTime occurredAt,
    required String category,
    required String memo,
    ImagePayload? receipt,
  }) async {}

  @override
  Future<void> deleteLedgerEntry({
    required String clubId,
    required String entryId,
  }) async {}

  @override
  Future<SettlementListData> loadSettlementList({
    required String uid,
    required String clubId,
  }) =>
      throw UnimplementedError();

  @override
  Future<SettlementDetailData> loadSettlement({
    required String uid,
    required String clubId,
    required String settlementId,
    bool allShares = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<SettlementDraftData> loadSettlementDraft({
    required String uid,
    required String clubId,
    String? settlementId,
  }) =>
      throw UnimplementedError();

  @override
  Future<String> saveSettlementDraft({
    required String clubId,
    required String actorId,
    String? settlementId,
    required String title,
    required String meetingId,
    required String meetingTitle,
    DateTime? meetingAt,
    required int supportAmount,
    required String receiverUserId,
    required String receiverName,
    required String bankName,
    required String bankAccount,
    required DateTime dueAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> saveSettlementRounds({
    required String clubId,
    required String settlementId,
    required List<SettlementRound> rounds,
  }) async {}

  @override
  Future<void> saveRoundAttendees({
    required String clubId,
    required String settlementId,
    required String roundId,
    required List<String> attendeeIds,
  }) async {}

  @override
  Future<void> calculateSettlement({
    required String clubId,
    required String settlementId,
  }) async {}

  @override
  Future<void> confirmSettlement({
    required String clubId,
    required String settlementId,
    required String actorId,
    required String actorName,
  }) async {}

  @override
  Future<void> reportSettlementPayment({
    required String clubId,
    required String settlementId,
    required String userId,
    required String depositName,
  }) async {}

  @override
  Future<void> confirmSettlementShare({
    required String clubId,
    required String settlementId,
    required String userId,
    required String actorId,
  }) async {}

  @override
  Future<void> remindUnsettled({
    required String clubId,
    required String settlementId,
    required String actorId,
  }) async {}
}
