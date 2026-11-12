import 'package:flutter_proj/models/club.dart';

enum MeetingFilter { upcoming, past, all }

bool _startsBeforeToday(ClubEvent event, DateTime now) {
  final start = event.startsAt;
  if (start == null) return false;
  final day = DateTime(start.year, start.month, start.day);
  final today = DateTime(now.year, now.month, now.day);
  return day.isBefore(today);
}

bool _isDoneStatus(ClubEvent event) {
  final status = event.status.toLowerCase();
  return status == 'past' || status == 'done' || status == '완료';
}

/// 지금 실제로 출석을 받을 수 있는 모임인지 봅니다.
/// 운영진이 출석을 닫지 않았더라도 모임 날짜가 지났으면 열린 것으로 보지 않습니다.
bool isAttendanceLive(ClubEvent event, DateTime now) {
  if (!event.attendanceOpen) return false;
  if (_isDoneStatus(event)) return false;
  return !_startsBeforeToday(event, now);
}

bool isPastMeeting(ClubEvent event, DateTime now) {
  if (isAttendanceLive(event, now)) return false;
  if (_isDoneStatus(event)) return true;
  return _startsBeforeToday(event, now);
}

List<ClubEvent> filterMeetings(List<ClubEvent> events, MeetingFilter filter, DateTime now) {
  return events.where((event) {
    final past = isPastMeeting(event, now);
    return switch (filter) {
      MeetingFilter.all => true,
      MeetingFilter.past => past,
      MeetingFilter.upcoming => !past,
    };
  }).toList();
}

List<ClubEvent> uniqueMeetings(List<ClubEvent> events) {
  final seen = <String>{};
  final unique = <ClubEvent>[];
  for (final event in events) {
    final start = event.startsAt;
    final when = start == null ? '' : '${start.year}-${start.month}-${start.day}-${start.hour}-${start.minute}';
    if (seen.add('${event.title.trim()}|$when')) unique.add(event);
  }
  return unique;
}

List<ClubEvent> todaysMeetings(List<ClubEvent> events, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return events.where((event) {
    final start = event.startsAt;
    if (start == null) return false;
    final day = DateTime(start.year, start.month, start.day);
    return day == today;
  }).toList();
}
