import 'package:flutter_proj/core/kst.dart';

String formatGrouped(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer';
}

String formatWon(int value) => '${formatGrouped(value)}원';

String formatMonthDay(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final weekday = weekdays[date.weekday - 1];
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.month}.${date.day} ($weekday) $hour:$minute';
}

String formatShortDay(DateTime date) => '${date.month}.${date.day}';

String formatPickerDate(DateTime date) {
  const weeks = ['월', '화', '수', '목', '금', '토', '일'];
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}. $month. $day (${weeks[date.weekday - 1]})';
}

String formatDueLabel(DateTime date) {
  const weeks = ['월', '화', '수', '목', '금', '토', '일'];
  final day = date.day.toString().padLeft(2, '0');
  return '${date.month}.$day (${weeks[date.weekday - 1]})';
}

String formatWeekdayClock(DateTime date) {
  const weeks = ['월', '화', '수', '목', '금', '토', '일'];
  return '${weeks[date.weekday - 1]} ${formatClock(date)}';
}

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String meetingClubLabel(String clubName) {
  final name = clubName.trim();
  return '${name.isEmpty ? '동아리' : name} 모임';
}

String formatInviteUntil(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  return '${date.month}.$day까지 유효';
}

String formatClock(DateTime time) {
  final hour = time.hour;
  final marker = hour < 12 ? '오전' : '오후';
  final shown = hour % 12 == 0 ? 12 : hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$marker $shown:$minute';
}

String formatMeetingWhen(DateTime start, [DateTime? end]) {
  const weeks = ['월', '화', '수', '목', '금', '토', '일'];
  final label = '${start.month}.${start.day} (${weeks[start.weekday - 1]}) ${formatClock(start)}';
  if (end == null) return label;
  return '$label ~ ${formatClock(end)}';
}

String formatNoticeTime(DateTime time, [DateTime? now]) {
  final clock = now ?? kstNow();
  final hm = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  final today = DateTime(clock.year, clock.month, clock.day);
  final day = DateTime(time.year, time.month, time.day);
  if (day == today) return '오늘 $hm';
  if (day == today.subtract(const Duration(days: 1))) return '어제 $hm';
  return '${time.month}.${time.day} $hm';
}

int? parseWon(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}
