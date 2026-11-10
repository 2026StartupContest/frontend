import 'package:flutter_proj/models/club.dart';

enum AttendanceMethod { qr, manual }

class AttendanceRecord {
  const AttendanceRecord({
    required this.userId,
    required this.userName,
    required this.method,
    required this.checkedAt,
    this.reason,
    this.actorId,
    this.actorName,
  });

  final String userId;
  final String userName;
  final AttendanceMethod method;

  /// 한국 시간 기준 벽시계 시각입니다.
  final DateTime checkedAt;
  final String? reason;
  final String? actorId;
  final String? actorName;

  bool get isManual => method == AttendanceMethod.manual;

  String get initial =>
      userName.isEmpty ? '모' : String.fromCharCode(userName.runes.first);

  String get methodLabel => isManual ? '운영진이 출석 처리' : 'QR 출석';
}

class QrSession {
  const QrSession({required this.token, required this.expiresAt});

  final String token;

  /// 기기 시계와 바로 비교할 수 있는 실제 시각입니다.
  final DateTime expiresAt;

  Duration remaining(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);
}

class CheckInResult {
  const CheckInResult({
    required this.clubId,
    required this.event,
    required this.record,
    required this.duplicate,
  });

  final String clubId;
  final ClubEvent event;
  final AttendanceRecord record;

  /// 이미 출석한 모임의 QR을 다시 찍었을 때 true입니다.
  final bool duplicate;
}

class AttendanceRate {
  const AttendanceRate({required this.attended, required this.total});

  final int attended;
  final int total;

  int? get percent => total == 0 ? null : (attended * 100 / total).round();
}

class MemberRate {
  const MemberRate({
    required this.userId,
    required this.userName,
    required this.rate,
  });

  final String userId;
  final String userName;
  final AttendanceRate rate;
}

class AttendanceDoneArgs {
  const AttendanceDoneArgs({required this.result, this.role = 'member'});

  final CheckInResult result;
  final String role;
}
