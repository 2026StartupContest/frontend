import 'dart:async';

import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/view_models/base_view_model.dart';

String attendanceErrorText(Object error) {
  final text = error.toString();
  if (text.contains('permission-denied')) {
    return '권한이 없거나 출석 규칙이 아직 적용되지 않았어요.';
  }
  return text.replaceFirst('Bad state: ', '');
}

/// 모임 하나의 정보와 출석 기록을 실시간으로 받아 둡니다.
class MeetingAttendanceFeed extends BaseViewModel {
  MeetingAttendanceFeed({
    required ClubGateway clubs,
    required String clubId,
    required String eventId,
  }) {
    _eventSub = clubs
        .watchEvent(clubId: clubId, eventId: eventId)
        .listen((event) {
          _event = event;
          notifyListeners();
        }, onError: setError);
    _recordSub = clubs
        .watchAttendance(clubId: clubId, eventId: eventId)
        .listen((records) {
          _records = records;
          notifyListeners();
        }, onError: setError);
  }

  StreamSubscription<ClubEvent>? _eventSub;
  StreamSubscription<List<AttendanceRecord>>? _recordSub;
  ClubEvent? _event;
  List<AttendanceRecord> _records = const [];

  ClubEvent? get event => _event;

  /// 참석 대상의 출석 기록입니다. 최근에 출석한 순서입니다.
  List<AttendanceRecord> get records {
    final event = _event;
    return event == null ? const [] : presentRecords(event, _records);
  }

  int get total => _event?.attendeeIds.length ?? 0;

  int get checked => records.length;

  int get remaining => total - checked;

  double get progress => total == 0 ? 0 : checked / total;

  int get percent => total == 0 ? 0 : (checked * 100 / total).round();

  String? get message => error == null ? null : attendanceErrorText(error!);

  @override
  void dispose() {
    _eventSub?.cancel();
    _recordSub?.cancel();
    super.dispose();
  }
}
