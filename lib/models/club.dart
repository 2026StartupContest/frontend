import 'package:flutter_proj/models/app_user.dart';

class Club {
  const Club({
    required this.id,
    required this.name,
    required this.tagline,
    required this.category,
    required this.joinPolicy,
    required this.ownerId,
    required this.ownerName,
    required this.memberCount,
    required this.balance,
    required this.duesPaidCount,
    required this.duesTotalCount,
    required this.duesMonthLabel,
    this.feeAmount,
    this.imageUrl,
    this.bankName,
    this.bankAccount,
    this.accountHolder,
    this.inviteCode,
    this.inviteExpiresAt,
  });

  final String id;
  final String name;
  final String tagline;
  final String category;
  final String joinPolicy;
  final int? feeAmount;
  final String? imageUrl;
  final String ownerId;
  final String ownerName;
  final int memberCount;
  final String? bankName;
  final String? bankAccount;
  final String? accountHolder;
  final int balance;
  final int duesPaidCount;
  final int duesTotalCount;
  final String duesMonthLabel;
  final String? inviteCode;
  final DateTime? inviteExpiresAt;

  bool get requiresApproval => joinPolicy == 'approval';

  String get joinPolicyLabel => requiresApproval ? '승인 후 가입' : '바로 가입';

  String? get bankLine {
    if (bankName == null && bankAccount == null) return null;
    return '${bankName ?? ''} ${bankAccount ?? ''}'.trim();
  }
}

class InviteCode {
  const InviteCode({
    required this.code,
    required this.clubId,
    required this.expiresAt,
  });

  final String code;
  final String clubId;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class ClubPreview {
  const ClubPreview({required this.club, required this.memberCount});

  final Club club;
  final int memberCount;
}

class CreatedClub {
  const CreatedClub({required this.club, required this.invite});

  final Club club;
  final InviteCode invite;
}

class Membership {
  const Membership({
    required this.clubId,
    required this.userId,
    required this.userName,
    required this.role,
    required this.status,
    required this.feeReported,
    this.depositName,
    this.requestedAt,
  });

  final String clubId;
  final String userId;
  final String userName;
  final String role;
  final String status;
  final String? depositName;
  final bool feeReported;
  final DateTime? requestedAt;

  bool get isPending => status == 'pending';
}

class PendingView {
  const PendingView({required this.club, required this.membership});

  final Club club;
  final Membership membership;
}

class ClubEvent {
  const ClubEvent({
    required this.id,
    required this.badge,
    required this.title,
    required this.schedule,
    required this.artKicker,
    required this.artTitle,
    this.imageUrl,
    this.attendanceOpen = false,
    this.attendeeInitials = const [],
    this.attendeeSummary = '',
    this.startsAt,
    this.endsAt,
    this.place = '',
    this.status = '',
    this.description = '',
    this.supplies = '',
    this.attendeeIds = const [],
    this.checkedInCount = 0,
    this.feeAmount,
    this.feeDueAt,
    this.feePaidCount = 0,
  });

  final String id;
  final String badge;
  final String title;
  final String schedule;
  final String artKicker;
  final String artTitle;
  final String? imageUrl;
  final bool attendanceOpen;
  final List<String> attendeeInitials;
  final String attendeeSummary;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String place;
  final String status;
  final String description;
  final String supplies;
  final List<String> attendeeIds;
  final int checkedInCount;
  final int? feeAmount;
  final DateTime? feeDueAt;
  final int feePaidCount;

  int get attendeeCount =>
      attendeeIds.isEmpty ? attendeeInitials.length : attendeeIds.length;

  String get scheduleLine {
    if (place.isEmpty || schedule.contains(place)) return schedule;
    if (schedule.isEmpty) return place;
    return '$schedule  |  $place';
  }
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountNote,
  });

  final String id;
  final String title;
  final String subtitle;
  final int amount;
  final String amountNote;

  bool get income => amount >= 0;
}

class ClubNotice {
  const ClubNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.unread,
    required this.kind,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool unread;
  final String kind;
}

class HomeTask {
  const HomeTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.count,
  });

  final String id;
  final String title;
  final String subtitle;
  final String kind;
  final int? count;
}

class HomeData {
  const HomeData({
    required this.user,
    required this.club,
    required this.clubs,
    required this.events,
    required this.activities,
    required this.notices,
    required this.tasks,
    required this.role,
    required this.options,
    this.primaryClubId,
  });

  final AppUser user;
  final Club club;
  final List<Club> clubs;
  final List<ClubEvent> events;
  final List<ActivityItem> activities;
  final List<ClubNotice> notices;
  final List<HomeTask> tasks;
  final String role;
  final List<ClubOption> options;
  final String? primaryClubId;

  bool get hasUnread => notices.any((notice) => notice.unread);
}

class ClubOption {
  const ClubOption({
    required this.club,
    required this.role,
    required this.status,
    required this.primary,
  });

  final Club club;
  final String role;
  final String status;
  final bool primary;

  bool get isPending => status == 'pending';
}

class ProfileData {
  const ProfileData({required this.user, required this.options});

  final AppUser user;
  final List<ClubOption> options;

  bool owns(ClubOption option) =>
      option.role == 'owner' || option.club.ownerId == user.id;

  List<ClubOption> get ownedClubs =>
      options.where((option) => !option.isPending && owns(option)).toList();

  int get leavingClubCount => options.where((option) => !owns(option)).length;

  String get ownedLine {
    if (ownedClubs.isEmpty) return '없음';
    final names = ownedClubs.map((option) => option.club.name).join(', ');
    return '$names · 먼저 회장을 넘겨야 해요';
  }

  String get joinedLine =>
      leavingClubCount == 0 ? '없어요' : '$leavingClubCount곳에서 자동으로 나가요';

  List<ClubOption> get visibleClubs {
    final active = options.where((option) => !option.isPending).toList()
      ..sort((a, b) {
        if (a.primary != b.primary) return a.primary ? -1 : 1;
        return a.club.name.compareTo(b.club.name);
      });
    return active;
  }
}

class ClubMember {
  const ClubMember({
    required this.userId,
    required this.userName,
    required this.role,
    required this.status,
    this.duty,
    this.joinedAt,
    this.unpaidDues,
    this.unsettledAmount,
  });

  final String userId;
  final String userName;
  final String role;
  final String status;
  final String? duty;
  final DateTime? joinedAt;
  final int? unpaidDues;
  final int? unsettledAmount;

  String get initial =>
      userName.isEmpty ? '모' : String.fromCharCode(userName.runes.first);

  String get subtitle {
    if (role == 'owner') {
      final at = joinedAt;
      if (at == null) return '동아리 개설';
      return '동아리 개설 · ${at.year}.${at.month.toString().padLeft(2, '0')}';
    }
    final note = duty?.trim() ?? '';
    if (note.isNotEmpty) return note;
    final at = joinedAt;
    if (at == null) return '';
    return '${at.year}.${at.month.toString().padLeft(2, '0')} 가입';
  }
}

class ClubDesk {
  const ClubDesk({
    required this.user,
    required this.club,
    required this.myRole,
    required this.members,
    required this.requests,
  });

  final AppUser user;
  final Club club;
  final String myRole;
  final List<ClubMember> members;
  final List<Membership> requests;

  int get adminCount =>
      members.where((member) => member.role == 'admin').length;

  int get reportedCount =>
      requests.where((request) => request.feeReported).length;

  int get unpaidCount => requests.length - reportedCount;
}

class ImagePayload {
  const ImagePayload({required this.bytes, required this.contentType});

  final List<int> bytes;
  final String contentType;
}

abstract final class ClubOptions {
  static const categories = ['동아리', '학회', '스터디', '운동 · 취미', '기타'];
  static const approval = 'approval';
  static const open = 'open';
}
