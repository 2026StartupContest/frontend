import 'package:flutter/material.dart';
import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

class AttendanceDoneScreen extends StatefulWidget {
  const AttendanceDoneScreen({
    super.key,
    required this.deps,
    required this.args,
  });

  final MoaDependencies deps;
  final AttendanceDoneArgs args;

  @override
  State<AttendanceDoneScreen> createState() => _AttendanceDoneScreenState();
}

class _AttendanceDoneScreenState extends State<AttendanceDoneScreen> {
  AttendanceRate? _rate;

  CheckInResult get _result => widget.args.result;

  @override
  void initState() {
    super.initState();
    _loadRate();
  }

  Future<void> _loadRate() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final now = kstNow();
      final events = await widget.deps.clubs.loadMeetings(
        clubId: _result.clubId,
      );
      final records = await widget.deps.clubs.loadAttendanceRecords(
        clubId: _result.clubId,
        eventIds: attendanceHistoryIds(events, now),
      );
      final rate = attendanceRateFor(
        userId: uid,
        events: semesterMeetings(events, semesterOf(now)),
        records: records,
        now: now,
      );
      if (mounted) setState(() => _rate = rate);
    } catch (_) {
      // 출석은 이미 끝났으니 출석률을 못 불러와도 화면은 그대로 둡니다.
    }
  }

  void _goHome() => goClubHome(context, _result.clubId);

  void _openDetail() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.meetingDetail,
      arguments: MeetingArgs(
        clubId: _result.clubId,
        eventId: _result.event.id,
        role: widget.args.role,
      ),
    );
  }

  String get _rateLine {
    final rate = _rate;
    final percent = rate?.percent;
    if (rate == null || percent == null) return '-';
    return '$percent% (${rate.total}회 중 ${rate.attended}회)';
  }

  @override
  Widget build(BuildContext context) {
    final event = _result.event;
    final record = _result.record;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AttendanceAppBar(close: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                children: [
                  AttendanceStatusHero(
                    icon: 'check',
                    iconBackground: AppColors.primary,
                    title: '출석 완료!',
                    lines: [
                      '${event.title}에',
                      '${formatHm(record.checkedAt)}에 출석했어요.',
                    ],
                  ),
                  const SizedBox(height: 13),
                  AttendanceInfoCard(
                    rows: [
                      ('모임', event.title, null),
                      ('출석 시간', formatMonthDay(record.checkedAt), null),
                      ('출석 방법', 'QR 스캔', null),
                      ('내 출석률', _rateLine, AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => showMoaSheet(
                        context,
                        title: 'QR을 한 번 더 찍으면?',
                        body:
                            '같은 모임에는 한 번만 출석할 수 있어요. 다시 찍어도 처음 출석한 시간이 그대로 남아요.',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'QR을 한 번 더 찍으면?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.4,
                          color: AppColors.muted,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AttendanceBottomBar(
              children: [
                AttendanceButton(
                  label: '홈으로',
                  height: 44,
                  tone: AttendanceButtonTone.soft,
                  onPressed: _goHome,
                ),
                AttendanceButton(
                  label: '모임 상세 보기',
                  height: 44,
                  onPressed: _openDetail,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
