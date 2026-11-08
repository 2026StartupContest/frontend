import 'package:flutter_proj/models/club.dart';

enum MeetingFilter { upcoming, past, all }

bool isPastMeeting(ClubEvent event, DateTime now) {
  if (event.attendanceOpen) return false;
  final status = event.status.toLowerCase();
  if (status == 'past' || status == 'done' || status == '완료') return true;
  final start = event.startsAt;
  if (start == null) return false;
  final day = DateTime(start.year, start.month, start.day);
  final today = DateTime(now.year, now.month, now.day);
  return day.isBefore(today);
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
