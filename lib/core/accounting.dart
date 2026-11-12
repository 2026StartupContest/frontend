import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/models/accounting.dart';
import 'package:flutter_proj/models/club.dart';

abstract final class AccountingSegment {
  static const dues = 'dues';
  static const ledger = 'ledger';
}

abstract final class DuesStatus {
  static const unpaid = 'unpaid';
  static const reported = 'reported';
  static const paid = 'paid';
}

abstract final class LedgerKind {
  static const income = 'income';
  static const expense = 'expense';
}

const ledgerCategories = ['물품 구매', '활동비', '모임 지원', '기타'];

/// 홈 「차곡차곡, 최근 기록」에 보일 회계 장부 최신 거래입니다. 지출은 음수 금액입니다.
List<ActivityItem> recentLedgerActivities(
  Iterable<LedgerEntry> entries, {
  int limit = 5,
}) {
  final sorted = entries.toList()
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return [
    for (final entry in sorted.take(limit))
      ActivityItem(
        id: entry.id,
        title: entry.title,
        subtitle:
            '${formatShortDay(entry.occurredAt)} · ${entry.income ? '수입' : '지출'}',
        amount: entry.income ? entry.amount.abs() : -entry.amount.abs(),
        amountNote: entry.memo.isNotEmpty ? entry.memo : entry.category,
      ),
  ];
}

/// 같은 이름이면서 납부 기한이 같은 달인 회비가 이미 있는지 봅니다(#30).
/// 회비 설정을 다시 저장하거나 연타해서 같은 달 회비가 두 번 생기는 것을 막습니다.
bool hasDuplicateDuesRound(
  Iterable<DuesRound> rounds, {
  required String title,
  required DateTime dueAt,
}) {
  final name = title.trim();
  return rounds.any((round) {
    final due = round.dueAt;
    return round.title.trim() == name &&
        due != null &&
        due.year == dueAt.year &&
        due.month == dueAt.month;
  });
}

bool canManageBooks(String role) => ClubAccess.showsSettings(role);

bool canRecordLedger(String role) => canManageBooks(role);

List<DuesPayment> visibleDuesPayments({
  required String role,
  required String userId,
  required List<DuesPayment> payments,
}) {
  if (canManageBooks(role)) return payments;
  return [
    for (final payment in payments)
      if (payment.userId == userId) payment,
  ];
}

List<DuesPayment> filterDuesPayments(
  List<DuesPayment> payments,
  String status,
) {
  if (status == 'all') return payments;
  return [
    for (final payment in payments)
      if (payment.status == status) payment,
  ];
}

List<DuesPayment> sortDuesPayments(List<DuesPayment> payments) {
  final copy = [...payments];
  copy.sort((a, b) {
    final rank = _statusRank(a.status).compareTo(_statusRank(b.status));
    if (rank != 0) return rank;
    return a.userName.compareTo(b.userName);
  });
  return copy;
}

int _statusRank(String status) => switch (status) {
  DuesStatus.reported => 0,
  DuesStatus.unpaid => 1,
  _ => 2,
};

class DuesProgress {
  const DuesProgress({
    required this.paidCount,
    required this.reportedCount,
    required this.unpaidCount,
    required this.collected,
    required this.expected,
  });

  final int paidCount;
  final int reportedCount;
  final int unpaidCount;
  final int collected;
  final int expected;

  int get total => paidCount + reportedCount + unpaidCount;

  int get percent =>
      expected == 0 ? 0 : ((collected / expected) * 100).round();
}

DuesProgress duesProgress(List<DuesPayment> payments) {
  var paidCount = 0;
  var reportedCount = 0;
  var unpaidCount = 0;
  var collected = 0;
  var expected = 0;
  for (final payment in payments) {
    expected += payment.amount;
    switch (payment.status) {
      case DuesStatus.paid:
        paidCount += 1;
        collected += payment.amount;
      case DuesStatus.reported:
        reportedCount += 1;
      default:
        unpaidCount += 1;
    }
  }
  return DuesProgress(
    paidCount: paidCount,
    reportedCount: reportedCount,
    unpaidCount: unpaidCount,
    collected: collected,
    expected: expected,
  );
}

int paidDuesInYear(List<DuesPayment> payments, int year) {
  var sum = 0;
  for (final payment in payments) {
    if (payment.status != DuesStatus.paid) continue;
    final when = payment.confirmedAt ?? payment.dueAt;
    if (when != null && when.year != year) continue;
    sum += payment.amount;
  }
  return sum;
}

int ledgerBalance(Iterable<LedgerEntry> entries) {
  var sum = 0;
  for (final entry in entries) {
    sum += entry.signedAmount;
  }
  return sum;
}

class MonthLedgerTotals {
  const MonthLedgerTotals({required this.income, required this.expense});

  final int income;
  final int expense;
}

MonthLedgerTotals monthLedgerTotals(
  Iterable<LedgerEntry> entries,
  DateTime month,
) {
  var income = 0;
  var expense = 0;
  for (final entry in entries) {
    if (entry.occurredAt.year != month.year ||
        entry.occurredAt.month != month.month) {
      continue;
    }
    if (entry.income) {
      income += entry.amount;
    } else {
      expense += entry.amount;
    }
  }
  return MonthLedgerTotals(income: income, expense: expense);
}

List<LedgerEntry> filterLedgerEntries({
  required List<LedgerEntry> entries,
  required String range,
  required String kind,
  required DateTime now,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final start = switch (range) {
    'month' => DateTime(now.year, now.month),
    'quarter' => DateTime(now.year, now.month - 2),
    'year' => DateTime(now.year),
    'custom' => customStart,
    _ => null,
  };
  final end = range == 'custom' ? customEnd : null;
  return [
    for (final entry in entries)
      if (_inRange(entry.occurredAt, start, end) &&
          (kind == 'all' || entry.kind == kind))
        entry,
  ];
}

bool _inRange(DateTime time, DateTime? start, DateTime? end) {
  final day = DateTime(time.year, time.month, time.day);
  if (start != null && day.isBefore(DateTime(start.year, start.month, start.day))) {
    return false;
  }
  if (end != null && day.isAfter(DateTime(end.year, end.month, end.day))) {
    return false;
  }
  return true;
}

String duesStatusLabel(String status) => switch (status) {
  DuesStatus.paid => '납부 완료',
  DuesStatus.reported => '확인 대기',
  _ => '미납',
};
