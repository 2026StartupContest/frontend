import 'package:flutter_proj/models/accounting.dart';
import 'package:flutter_proj/models/settlement.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';

class LaunchTarget {
  const LaunchTarget(this.route, [this.arguments]);

  final String route;
  final Object? arguments;
}

abstract class AuthGateway {
  String? get currentUid;
  String? get currentEmail;
  String? get currentDisplayName;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<void> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  Future<void> ensureRecentLogin();

  Future<void> deleteAccount();
}

abstract class ClubGateway {
  Future<void> ensureUser({
    required String id,
    required String name,
    required String email,
    bool activityAlerts = false,
  });

  Future<AppUser?> getUser(String uid);

  Future<ProfileData> loadProfile(String uid);

  Future<void> updateNickname({required String uid, required String nickname});

  Future<void> updateActivityAlerts({
    required String uid,
    required bool enabled,
  });

  Future<void> deleteAccountData(String uid);

  Future<LaunchTarget> launchFor(String uid);

  Future<CreatedClub> createClub({
    required String ownerId,
    required String ownerName,
    required String name,
    required String tagline,
    required String category,
    required String joinPolicy,
    int? feeAmount,
    ImagePayload? image,
  });

  Future<ClubPreview?> findByCode(String code);

  Future<void> joinImmediately({
    required String uid,
    required String userName,
    required Club club,
  });

  Future<void> requestJoin({
    required String uid,
    required String userName,
    required Club club,
    required String depositName,
    required bool feeReported,
  });

  Future<PendingView> loadPending({
    required String uid,
    required String clubId,
  });

  Future<void> cancelJoin({required String uid, required String clubId});

  Future<void> askOwner({
    required String uid,
    required String userName,
    required String clubId,
  });

  Future<HomeData> loadHome({required String uid, required String clubId});

  Future<void> markNoticesRead(String clubId);

  Future<ClubDesk> loadDesk({required String uid, required String clubId});

  Future<void> setPrimaryClub({required String uid, required String clubId});

  Future<void> updateClubName({
    required String clubId,
    required String name,
    ImagePayload? image,
  });

  Future<void> updateJoinPolicy({
    required String clubId,
    required String joinPolicy,
  });

  Future<void> updateFeeAmount({
    required String clubId,
    required int? feeAmount,
  });

  Future<String> reissueInvite({required String clubId});

  Future<void> setMemberRole({
    required String clubId,
    required String userId,
    required String role,
  });

  Future<void> transferOwnership({
    required String clubId,
    required String fromUserId,
    required String toUserId,
  });

  Future<void> removeMember({required String clubId, required String userId});

  Future<void> approveJoins({
    required String clubId,
    required List<String> userIds,
  });

  Future<void> rejectJoins({
    required String clubId,
    required List<String> userIds,
  });

  Future<String?> deleteClub({required String uid, required String clubId});

  Future<ClubEvent> loadEvent({
    required String clubId,
    required String eventId,
  });

  Future<String> saveMeeting({
    required String clubId,
    required ClubEvent event,
    ImagePayload? image,
  });

  Future<void> setMeetingStatus({
    required String clubId,
    required String eventId,
    required String status,
  });

  Future<void> setMeetingAttendees({
    required String clubId,
    required String eventId,
    required List<String> attendeeIds,
  });

  Future<void> deleteMeeting({required String clubId, required String eventId});

  Future<List<ClubEvent>> loadMeetings({required String clubId});

  Stream<ClubEvent> watchEvent({
    required String clubId,
    required String eventId,
  });

  /// 최근에 출석한 순서로 줍니다.
  Stream<List<AttendanceRecord>> watchAttendance({
    required String clubId,
    required String eventId,
  });

  Future<Map<String, List<AttendanceRecord>>> loadAttendanceRecords({
    required String clubId,
    required List<String> eventIds,
  });

  /// 운영진만 볼 수 있습니다. 아직 QR을 띄운 적이 없으면 null입니다.
  Stream<QrSession?> watchAttendanceQr({
    required String clubId,
    required String eventId,
  });

  /// 새 QR 토큰을 만들고 출석을 엽니다.
  Future<QrSession> rotateAttendanceQr({
    required String clubId,
    required String eventId,
  });

  Future<void> closeAttendance({
    required String clubId,
    required String eventId,
  });

  /// [raw]는 스캔한 QR 내용 그대로입니다.
  Future<CheckInResult> checkInWithQr({
    required String uid,
    required String raw,
  });

  Future<void> markAttendanceManually({
    required String clubId,
    required String eventId,
    required String userId,
    required String userName,
    required String actorId,
    required String actorName,
    String? reason,
  });

  Future<AccountingData> loadAccounting({
    required String uid,
    required String clubId,
  });

  Future<void> registerDues({
    required String clubId,
    required String actorId,
    required String title,
    required int amount,
    required DateTime dueAt,
    required String repeat,
    required bool allMembers,
    required List<DuesTarget> targets,
  });

  Future<void> reportDuesPayment({
    required String clubId,
    required String duesId,
    required String userId,
    required String depositName,
  });

  Future<void> confirmDuesPayment({
    required String clubId,
    required String duesId,
    required String userId,
    required String actorId,
    required String actorName,
    required String ledgerTitle,
    required int amount,
  });

  Future<void> remindUnpaidDues({
    required String clubId,
    required String actorId,
    required String title,
    required String body,
  });

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
  });

  Future<void> deleteLedgerEntry({
    required String clubId,
    required String entryId,
  });

  Future<SettlementListData> loadSettlementList({
    required String uid,
    required String clubId,
  });

  Future<SettlementDetailData> loadSettlement({
    required String uid,
    required String clubId,
    required String settlementId,
    bool allShares = false,
  });

  Future<SettlementDraftData> loadSettlementDraft({
    required String uid,
    required String clubId,
    String? settlementId,
  });

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
  });

  Future<void> saveSettlementRounds({
    required String clubId,
    required String settlementId,
    required List<SettlementRound> rounds,
  });

  Future<void> saveRoundAttendees({
    required String clubId,
    required String settlementId,
    required String roundId,
    required List<String> attendeeIds,
  });

  Future<void> calculateSettlement({
    required String clubId,
    required String settlementId,
  });

  Future<void> confirmSettlement({
    required String clubId,
    required String settlementId,
    required String actorId,
    required String actorName,
  });

  Future<void> reportSettlementPayment({
    required String clubId,
    required String settlementId,
    required String userId,
    required String depositName,
  });

  Future<void> confirmSettlementShare({
    required String clubId,
    required String settlementId,
    required String userId,
    required String actorId,
  });

  Future<void> remindUnsettled({
    required String clubId,
    required String settlementId,
    required String actorId,
  });
}
