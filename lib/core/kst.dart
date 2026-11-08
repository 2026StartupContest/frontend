const kstOffset = Duration(hours: 9);

DateTime toKst(DateTime time) {
  final utc = time.toUtc();
  final shifted = utc.add(kstOffset);
  return DateTime(
    shifted.year,
    shifted.month,
    shifted.day,
    shifted.hour,
    shifted.minute,
    shifted.second,
    shifted.millisecond,
  );
}

DateTime kstNow() => toKst(DateTime.now());

DateTime kstWallToInstant(DateTime wall) {
  return DateTime.utc(
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
    wall.second,
    wall.millisecond,
  ).subtract(kstOffset);
}
