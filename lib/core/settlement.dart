import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/models/settlement.dart';

class RoundSplitInput {
  const RoundSplitInput({
    required this.id,
    required this.index,
    required this.amount,
    required this.attendeeIds,
  });

  final String id;
  final int index;
  final int amount;
  final List<String> attendeeIds;
}

class RoundSplitResult {
  const RoundSplitResult({
    required this.id,
    required this.index,
    required this.gross,
    required this.supportApplied,
    required this.net,
    required this.shares,
  });

  final String id;
  final int index;
  final int gross;
  final int supportApplied;
  final int net;
  final Map<String, int> shares;

  int get representativeShare {
    if (shares.isEmpty) return 0;
    final counts = <int, int>{};
    for (final amount in shares.values) {
      counts[amount] = (counts[amount] ?? 0) + 1;
    }
    var best = shares.values.first;
    var bestCount = -1;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }
}

class PersonSplit {
  const PersonSplit({
    required this.userId,
    required this.amount,
    required this.roundIndexes,
    required this.roundAmounts,
  });

  final String userId;
  final int amount;
  final List<int> roundIndexes;
  final List<int> roundAmounts;
}

class SettlementShareGroup {
  const SettlementShareGroup({
    required this.roundIndexes,
    required this.amount,
    required this.count,
    required this.roundCount,
  });

  final List<int> roundIndexes;
  final int amount;
  final int count;
  final int roundCount;

  String get label {
    if (roundIndexes.isEmpty) return '참석 ($count명)';
    final joined = '${roundIndexes.join('·')}차';
    final only = roundIndexes.length == 1 && roundCount > 1;
    final name = only ? '$joined만 참석' : '$joined 참석';
    return '$name ($count명)';
  }
}

class SettlementSplit {
  const SettlementSplit({
    required this.rounds,
    required this.people,
    required this.totalSpend,
    required this.supportApplied,
    required this.personalTotal,
  });

  final List<RoundSplitResult> rounds;
  final List<PersonSplit> people;
  final int totalSpend;
  final int supportApplied;
  final int personalTotal;

  List<SettlementShareGroup> get groups {
    final grouped = <String, SettlementShareGroup>{};
    for (final person in people) {
      final key = '${person.roundIndexes.join(',')}:${person.amount}';
      final current = grouped[key];
      grouped[key] = SettlementShareGroup(
        roundIndexes: person.roundIndexes,
        amount: person.amount,
        count: (current?.count ?? 0) + 1,
        roundCount: rounds.length,
      );
    }
    final list = grouped.values.toList();
    list.sort((a, b) {
      final depth = b.roundIndexes.length.compareTo(a.roundIndexes.length);
      if (depth != 0) return depth;
      return a.roundIndexes.join().compareTo(b.roundIndexes.join());
    });
    return list;
  }
}

List<String> uniqueAttendees(List<String> ids) {
  final seen = <String>{};
  final unique = <String>[];
  for (final id in ids) {
    final trimmed = id.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) continue;
    unique.add(trimmed);
  }
  return unique;
}

Map<String, int> splitWon(int net, List<String> attendeeIds) {
  final ids = uniqueAttendees(attendeeIds);
  if (ids.isEmpty) return const {};
  final amount = net < 0 ? 0 : net;
  final base = amount ~/ ids.length;
  final extra = amount % ids.length;
  return {
    for (var i = 0; i < ids.length; i++) ids[i]: base + (i < extra ? 1 : 0),
  };
}

SettlementSplit splitSettlement({
  required List<RoundSplitInput> rounds,
  required int supportAmount,
}) {
  final ordered = [...rounds]..sort((a, b) => a.index.compareTo(b.index));
  var remaining = supportAmount < 0 ? 0 : supportAmount;
  final results = <RoundSplitResult>[];
  var totalSpend = 0;
  var supportApplied = 0;
  for (final round in ordered) {
    final gross = round.amount < 0 ? 0 : round.amount;
    final applied = remaining > gross ? gross : remaining;
    remaining -= applied;
    supportApplied += applied;
    totalSpend += gross;
    final net = gross - applied;
    results.add(
      RoundSplitResult(
        id: round.id,
        index: round.index,
        gross: gross,
        supportApplied: applied,
        net: net,
        shares: splitWon(net, round.attendeeIds),
      ),
    );
  }
  final people = <String, PersonSplit>{};
  final order = <String>[];
  for (var i = 0; i < results.length; i++) {
    final round = results[i];
    final ids = uniqueAttendees(ordered[i].attendeeIds);
    for (final id in ids) {
      final share = round.shares[id] ?? 0;
      final current = people[id];
      if (current == null) {
        order.add(id);
        people[id] = PersonSplit(
          userId: id,
          amount: share,
          roundIndexes: [round.index],
          roundAmounts: [share],
        );
      } else {
        people[id] = PersonSplit(
          userId: id,
          amount: current.amount + share,
          roundIndexes: [...current.roundIndexes, round.index],
          roundAmounts: [...current.roundAmounts, share],
        );
      }
    }
  }
  final positive = [
    for (final id in order)
      if ((people[id]?.amount ?? 0) > 0) people[id]!,
  ];
  final personalTotal = positive.fold<int>(
    0,
    (sum, person) => sum + person.amount,
  );
  return SettlementSplit(
    rounds: results,
    people: positive,
    totalSpend: totalSpend,
    supportApplied: supportApplied,
    personalTotal: personalTotal,
  );
}

String? settlementReadyIssue(
  List<RoundSplitInput> rounds, {
  required int supportAmount,
}) {
  if (rounds.isEmpty) return '차수를 하나 이상 입력해 주세요.';
  if (supportAmount < 0) return '지원 금액을 확인해 주세요.';
  for (final round in rounds) {
    final label = '${round.index}차';
    if (round.amount <= 0) return '$label 금액을 입력해 주세요.';
    if (uniqueAttendees(round.attendeeIds).isEmpty)
      return '$label 참석자를 골라 주세요.';
  }
  return null;
}

String settlementShareMessage({
  required String title,
  required SettlementSplit split,
  required String bankName,
  required String bankAccount,
  required String receiverName,
}) {
  final parts = [
    for (final round in split.rounds)
      '${round.index}차 ${formatWon(round.representativeShare)}',
  ];
  final all = split.rounds.fold<int>(
    0,
    (sum, round) => sum + round.representativeShare,
  );
  final attendance = split.rounds.length > 1
      ? '모든 차수에 참석했다면 ${formatWon(all)}'
      : '1인 분담금 ${formatWon(all)}';
  final account = [
    bankName.trim(),
    bankAccount.trim(),
  ].where((part) => part.isNotEmpty).join(' ');
  final holder = receiverName.trim();
  final accountLine = holder.isEmpty ? account : '$account ($holder)'.trim();
  return [
    '${title.trim()} 정산',
    parts.join(' / '),
    attendance,
    accountLine,
    '입금 후 모아에서 ‘입금 완료’를 눌러 주세요.',
  ].where((line) => line.trim().isNotEmpty).join('\n');
}

bool settlementOverdue(Settlement settlement, [DateTime? now]) {
  final due = settlement.dueAt;
  if (!settlement.isCollecting || due == null) return false;
  final clock = now ?? kstNow();
  final dueDay = DateTime(due.year, due.month, due.day);
  final today = DateTime(clock.year, clock.month, clock.day);
  return dueDay.isBefore(today);
}

String settlementDueCaption(Settlement settlement, [DateTime? now]) {
  final due = settlement.dueAt;
  if (due == null) return '';
  final label = '기한 ${due.month}.${due.day}';
  return settlementOverdue(settlement, now) ? '$label 지남' : label;
}

List<SettlementShare> filterSettlementShares(
  List<SettlementShare> shares,
  String filter,
) {
  final filtered = switch (filter) {
    SettlementShareFilter.paid => shares.where((share) => share.paid).toList(),
    SettlementShareFilter.open => shares.where((share) => share.open).toList(),
    _ => [...shares],
  };
  filtered.sort((a, b) {
    final rank = _shareRank(a.status).compareTo(_shareRank(b.status));
    if (rank != 0) return rank;
    return a.userName.compareTo(b.userName);
  });
  return filtered;
}

int _shareRank(String status) => switch (status) {
  SettlementShareStatus.reported => 0,
  SettlementShareStatus.unpaid => 1,
  _ => 2,
};

int openShareCount(List<SettlementShare> shares) =>
    shares.where((share) => share.open).length;

String settlementListCaption(Settlement settlement) {
  final date = settlement.meetingAt == null
      ? ''
      : formatDayLabel(settlement.meetingAt!);
  final rounds = settlement.rounds
      .map((round) => round.shortHeading)
      .join(' + ');
  final people = '${settlement.participantCount}명';
  return [date, rounds, people].where((part) => part.isNotEmpty).join(' · ');
}

String settlementDoneSubtitle(Settlement settlement) {
  final rounds = settlement.rounds.isEmpty
      ? ''
      : '${settlement.rounds.length}차';
  final people = '${settlement.participantCount}명';
  final amount = formatWon(
    settlement.personalTotal > 0
        ? settlement.personalTotal
        : settlement.totalSpend,
  );
  return [rounds, people, amount].where((part) => part.isNotEmpty).join(' · ');
}
