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
    this.attendanceOpen = false,
    this.attendeeInitials = const [],
    this.attendeeSummary = '',
  });

  final String id;
  final String badge;
  final String title;
  final String schedule;
  final String artKicker;
  final String artTitle;
  final bool attendanceOpen;
  final List<String> attendeeInitials;
  final String attendeeSummary;
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
  });

  final AppUser user;
  final Club club;
  final List<Club> clubs;
  final List<ClubEvent> events;
  final List<ActivityItem> activities;
  final List<ClubNotice> notices;
  final List<HomeTask> tasks;

  bool get hasUnread => notices.any((notice) => notice.unread);
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
