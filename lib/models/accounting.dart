import 'package:flutter_proj/models/club.dart';

class DuesTarget {
  const DuesTarget({required this.userId, required this.userName});

  final String userId;
  final String userName;
}

class DuesRound {
  const DuesRound({
    required this.id,
    required this.title,
    required this.amount,
    required this.repeat,
    required this.target,
    required this.targetIds,
    this.dueAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final int amount;
  final DateTime? dueAt;
  final String repeat;
  final String target;
  final List<String> targetIds;
  final DateTime? createdAt;
}

class DuesPayment {
  const DuesPayment({
    required this.userId,
    required this.userName,
    required this.duesId,
    required this.duesTitle,
    required this.amount,
    required this.status,
    this.dueAt,
    this.depositName,
    this.reportedAt,
    this.confirmedAt,
  });

  final String userId;
  final String userName;
  final String duesId;
  final String duesTitle;
  final int amount;
  final String status;
  final DateTime? dueAt;
  final String? depositName;
  final DateTime? reportedAt;
  final DateTime? confirmedAt;

  String get initial =>
      userName.isEmpty ? '모' : String.fromCharCode(userName.runes.first);
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.title,
    required this.occurredAt,
    required this.category,
    required this.memo,
    required this.actorId,
    required this.actorName,
    this.receiptUrl,
    this.createdAt,
  });

  final String id;
  final String kind;
  final int amount;
  final String title;
  final DateTime occurredAt;
  final String category;
  final String memo;
  final String? receiptUrl;
  final String actorId;
  final String actorName;
  final DateTime? createdAt;

  bool get income => kind == 'income';

  int get signedAmount => income ? amount : -amount;
}

class AccountingData {
  const AccountingData({
    required this.club,
    required this.role,
    required this.userId,
    required this.userName,
    required this.members,
    required this.rounds,
    required this.currentPayments,
    required this.myPayments,
    required this.entries,
    required this.notices,
  });

  final Club club;
  final String role;
  final String userId;
  final String userName;
  final List<ClubMember> members;
  final List<DuesRound> rounds;
  final List<DuesPayment> currentPayments;
  final List<DuesPayment> myPayments;
  final List<LedgerEntry> entries;
  final List<ClubNotice> notices;

  bool get hasUnread => notices.any((notice) => notice.unread);

  DuesRound? get current => rounds.isEmpty ? null : rounds.first;
}
