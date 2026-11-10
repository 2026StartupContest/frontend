import 'package:flutter_proj/models/club.dart';

abstract final class SettlementStatus {
  static const draft = 'draft';
  static const collecting = 'collecting';
  static const done = 'done';
}

abstract final class SettlementShareStatus {
  static const unpaid = 'unpaid';
  static const reported = 'reported';
  static const paid = 'paid';
}

abstract final class SettlementShareFilter {
  static const all = 'all';
  static const paid = 'paid';
  static const open = 'open';
}

class SettlementRound {
  const SettlementRound({
    required this.id,
    required this.index,
    required this.label,
    required this.place,
    required this.amount,
    required this.attendeeIds,
    this.supportApplied = 0,
    this.net = 0,
    this.shareAmount = 0,
  });

  final String id;
  final int index;
  final String label;
  final String place;
  final int amount;
  final List<String> attendeeIds;
  final int supportApplied;
  final int net;
  final int shareAmount;

  String get heading =>
      label.trim().isEmpty ? '$index차' : '$index차 · ${label.trim()}';

  String get shortHeading =>
      label.trim().isEmpty ? '$index차' : '$index차 ${label.trim()}';

  SettlementRound copyWith({
    String? id,
    int? index,
    String? label,
    String? place,
    int? amount,
    List<String>? attendeeIds,
    int? supportApplied,
    int? net,
    int? shareAmount,
  }) {
    return SettlementRound(
      id: id ?? this.id,
      index: index ?? this.index,
      label: label ?? this.label,
      place: place ?? this.place,
      amount: amount ?? this.amount,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      supportApplied: supportApplied ?? this.supportApplied,
      net: net ?? this.net,
      shareAmount: shareAmount ?? this.shareAmount,
    );
  }
}

class SettlementShare {
  const SettlementShare({
    required this.userId,
    required this.userName,
    required this.amount,
    required this.roundIndexes,
    required this.roundAmounts,
    required this.status,
    this.depositName,
    this.reportedAt,
    this.confirmedAt,
  });

  final String userId;
  final String userName;
  final int amount;
  final List<int> roundIndexes;
  final List<int> roundAmounts;
  final String status;
  final String? depositName;
  final DateTime? reportedAt;
  final DateTime? confirmedAt;

  bool get paid => status == SettlementShareStatus.paid;

  bool get open => !paid;

  String get initial =>
      userName.isEmpty ? '모' : String.fromCharCode(userName.runes.first);

  String get attendanceLabel {
    if (roundIndexes.isEmpty) return '참석';
    if (roundIndexes.length == 1) return '${roundIndexes.first}차 참석';
    return '${roundIndexes.join('·')}차 참석';
  }
}

class Settlement {
  const Settlement({
    required this.id,
    required this.title,
    required this.meetingId,
    required this.meetingTitle,
    required this.status,
    required this.supportAmount,
    required this.receiverUserId,
    required this.receiverName,
    required this.bankName,
    required this.bankAccount,
    required this.dueAt,
    required this.createdBy,
    required this.shareCount,
    required this.paidCount,
    required this.collectedAmount,
    required this.personalTotal,
    required this.totalSpend,
    this.meetingAt,
    this.createdAt,
    this.confirmedAt,
    this.ledgerEntryId,
    this.rounds = const [],
    this.shares = const [],
  });

  final String id;
  final String title;
  final String meetingId;
  final String meetingTitle;
  final String status;
  final int supportAmount;
  final String receiverUserId;
  final String receiverName;
  final String bankName;
  final String bankAccount;
  final DateTime? dueAt;
  final DateTime? meetingAt;
  final DateTime? createdAt;
  final DateTime? confirmedAt;
  final String createdBy;
  final String? ledgerEntryId;
  final int shareCount;
  final int paidCount;
  final int collectedAmount;
  final int personalTotal;
  final int totalSpend;
  final List<SettlementRound> rounds;
  final List<SettlementShare> shares;

  bool get isDraft => status == SettlementStatus.draft;

  bool get isCollecting => status == SettlementStatus.collecting;

  bool get isDone => status == SettlementStatus.done;

  int get participantCount {
    if (shareCount > 0) return shareCount;
    return {for (final round in rounds) ...round.attendeeIds}.length;
  }

  SettlementShare? shareFor(String userId) {
    for (final share in shares) {
      if (share.userId == userId) return share;
    }
    return null;
  }

  String get accountLine {
    final bank = [
      bankName.trim(),
      bankAccount.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    final holder = receiverName.trim();
    if (bank.isEmpty) return holder;
    if (holder.isEmpty) return bank;
    return '$holder · $bank';
  }
}

class SettlementListData {
  const SettlementListData({
    required this.club,
    required this.role,
    required this.userId,
    required this.userName,
    required this.notices,
    required this.items,
  });

  final Club club;
  final String role;
  final String userId;
  final String userName;
  final List<ClubNotice> notices;
  final List<Settlement> items;

  bool get hasUnread => notices.any((notice) => notice.unread);
}

class SettlementDetailData {
  const SettlementDetailData({
    required this.club,
    required this.role,
    required this.userId,
    required this.userName,
    required this.settlement,
    required this.members,
  });

  final Club club;
  final String role;
  final String userId;
  final String userName;
  final Settlement settlement;
  final List<ClubMember> members;
}

class SettlementDraftData {
  const SettlementDraftData({
    required this.club,
    required this.role,
    required this.userId,
    required this.userName,
    required this.meetings,
    required this.members,
    this.settlement,
  });

  final Club club;
  final String role;
  final String userId;
  final String userName;
  final List<ClubEvent> meetings;
  final List<ClubMember> members;
  final Settlement? settlement;
}
