import 'dart:math';

import 'package:flutter_proj/core/meeting_filter.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';

const attendanceQrPrefix = 'moa-attendance';
const attendanceQrLifetime = Duration(minutes: 5);
const attendanceLowRate = 60;

const _tokenAlphabet =
    'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';

class AttendanceQrPayload {
  const AttendanceQrPayload({
    required this.clubId,
    required this.eventId,
    required this.token,
  });

  final String clubId;
  final String eventId;
  final String token;
}

String generateAttendanceToken({int length = 24, Random? random}) {
  final rng = random ?? Random.secure();
  return List.generate(
    length,
    (_) => _tokenAlphabet[rng.nextInt(_tokenAlphabet.length)],
  ).join();
}

String buildAttendanceQr({
  required String clubId,
  required String eventId,
  required String token,
}) {
  return '$attendanceQrPrefix:$clubId:$eventId:$token';
}

AttendanceQrPayload? parseAttendanceQr(String raw) {
  final parts = raw.trim().split(':');
  if (parts.length != 4 || parts.first != attendanceQrPrefix) return null;
  if (parts.any((part) => part.isEmpty)) return null;
  return AttendanceQrPayload(
    clubId: parts[1],
    eventId: parts[2],
    token: parts[3],
  );
}

String formatCountdown(Duration remaining) {
  final seconds = remaining.isNegative ? 0 : remaining.inSeconds;
  final minute = (seconds ~/ 60).toString().padLeft(2, '0');
  final second = (seconds % 60).toString().padLeft(2, '0');
  return '$minute:$second';
}

String formatHm(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// 1학기는 3~8월, 2학기는 9월부터 이듬해 2월까지입니다.
class Semester {
  const Semester(this.start, this.end);

  final DateTime start;

  /// 이 날짜부터는 다음 학기입니다.
  final DateTime end;

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  Semester get previous => semesterOf(start.subtract(const Duration(days: 1)));
}

Semester semesterOf(DateTime date) {
  if (date.month >= 3 && date.month <= 8) {
    return Semester(DateTime(date.year, 3), DateTime(date.year, 9));
  }
  final startYear = date.month >= 9 ? date.year : date.year - 1;
  return Semester(DateTime(startYear, 9), DateTime(startYear + 1, 3));
}

List<ClubEvent> semesterMeetings(List<ClubEvent> events, Semester semester) {
  return events.where((event) {
    final start = event.startsAt;
    return start != null && semester.contains(start);
  }).toList();
}

/// 참석 대상 중 실제로 출석한 사람의 기록만 남깁니다.
List<AttendanceRecord> presentRecords(
  ClubEvent event,
  List<AttendanceRecord> records,
) {
  final targets = event.attendeeIds.toSet();
  return records.where((record) => targets.contains(record.userId)).toList();
}

AttendanceRecord? recordOf(List<AttendanceRecord>? records, String userId) {
  if (records == null) return null;
  for (final record in records) {
    if (record.userId == userId) return record;
  }
  return null;
}

/// 출석 기록을 읽어 와야 하는 모임 id입니다. 이번 학기와 지난 학기만 봅니다.
List<String> attendanceHistoryIds(List<ClubEvent> events, DateTime now) {
  final current = semesterOf(now);
  final previous = current.previous;
  return [
    for (final event in events)
      if (event.startsAt != null &&
          (current.contains(event.startsAt!) ||
              previous.contains(event.startsAt!)) &&
          (event.checkedInCount > 0 || event.attendanceOpen))
        event.id,
  ];
}

/// 출석률 = 출석한 모임 수 ÷ 참석 대상이었던 모임 수.
/// 아직 끝나지 않은 모임은 출석한 경우에만 셉니다.
AttendanceRate attendanceRateFor({
  required String userId,
  required Iterable<ClubEvent> events,
  required Map<String, List<AttendanceRecord>> records,
  required DateTime now,
}) {
  var attended = 0;
  var total = 0;
  for (final event in events) {
    if (!event.attendeeIds.contains(userId)) continue;
    if (recordOf(records[event.id], userId) != null) {
      attended++;
      total++;
    } else if (isPastMeeting(event, now)) {
      total++;
    }
  }
  return AttendanceRate(attended: attended, total: total);
}

int countedMeetings({
  required Iterable<ClubEvent> events,
  required Map<String, List<AttendanceRecord>> records,
  required DateTime now,
}) {
  return events.where((event) {
    if (isPastMeeting(event, now)) return true;
    return presentRecords(event, records[event.id] ?? const []).isNotEmpty;
  }).length;
}

List<MemberRate> memberRates({
  required List<ClubMember> members,
  required Iterable<ClubEvent> events,
  required Map<String, List<AttendanceRecord>> records,
  required DateTime now,
}) {
  final rates = <MemberRate>[];
  for (final member in members) {
    final rate = attendanceRateFor(
      userId: member.userId,
      events: events,
      records: records,
      now: now,
    );
    if (rate.total == 0) continue;
    rates.add(
      MemberRate(userId: member.userId, userName: member.userName, rate: rate),
    );
  }
  return rates;
}

AttendanceRate averageRate(Iterable<MemberRate> rates) {
  var attended = 0;
  var total = 0;
  for (final item in rates) {
    attended += item.rate.attended;
    total += item.rate.total;
  }
  return AttendanceRate(attended: attended, total: total);
}

List<MemberRate> sortRates(List<MemberRate> rates, {required bool highFirst}) {
  final sorted = [...rates];
  sorted.sort((a, b) {
    final left = a.rate.attended * b.rate.total;
    final right = b.rate.attended * a.rate.total;
    final order = highFirst ? right.compareTo(left) : left.compareTo(right);
    if (order != 0) return order;
    return a.userName.compareTo(b.userName);
  });
  return sorted;
}

/// 출석 탭 맨 위에 올릴 모임을 고릅니다.
/// 출석이 열린 모임, 오늘 모임, 가장 가까운 다가오는 모임 순서입니다.
ClubEvent? currentAttendanceEvent(List<ClubEvent> events, DateTime now) {
  for (final event in events) {
    if (isAttendanceLive(event, now)) return event;
  }
  final today = todaysMeetings(events, now)
      .where((event) => !isPastMeeting(event, now))
      .toList()
    ..sort(_byStart);
  if (today.isNotEmpty) return today.first;
  final upcoming = events
      .where((event) => event.startsAt != null && !isPastMeeting(event, now))
      .toList()
    ..sort(_byStart);
  return upcoming.isEmpty ? null : upcoming.first;
}

/// 출석 탭의 최근 일정입니다.
/// 출석이 열린 모임, 다가오는 모임(가까운 순), 지난 모임(최근 순)으로 놓습니다.
List<ClubEvent> recentAttendanceEvents(
  List<ClubEvent> events,
  DateTime now, {
  int upcomingLimit = 2,
  int pastLimit = 4,
}) {
  final dated = events.where((event) => event.startsAt != null).toList();
  final open = dated.where((event) => isAttendanceLive(event, now)).toList()
    ..sort(_byStart);
  final upcoming = dated
      .where((event) => !isAttendanceLive(event, now) && !isPastMeeting(event, now))
      .toList()
    ..sort(_byStart);
  final past = dated
      .where((event) => !isAttendanceLive(event, now) && isPastMeeting(event, now))
      .toList()
    ..sort((a, b) => _byStart(b, a));
  return [
    ...open,
    ...upcoming.take(upcomingLimit),
    ...past.take(pastLimit),
  ];
}

int _byStart(ClubEvent a, ClubEvent b) => a.startsAt!.compareTo(b.startsAt!);
