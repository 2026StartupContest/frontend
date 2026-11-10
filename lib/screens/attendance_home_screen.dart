import 'package:flutter/material.dart';
import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/meeting_filter.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/view_models/meeting_attendance_feed.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/club_sheets.dart';
import 'package:flutter_proj/widgets/moa_bottom_nav.dart';

class AttendanceHomeScreen extends StatefulWidget {
  const AttendanceHomeScreen({
    super.key,
    required this.deps,
    required this.clubId,
  });

  final MoaDependencies deps;
  final String clubId;

  @override
  State<AttendanceHomeScreen> createState() => _AttendanceHomeScreenState();
}

class _AttendanceHomeScreenState extends State<AttendanceHomeScreen> {
  HomeData? _data;
  Map<String, List<AttendanceRecord>> _records = const {};
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final data = await widget.deps.clubs.loadHome(
        uid: uid,
        clubId: widget.clubId,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _message = null;
      });
      final records = await widget.deps.clubs.loadAttendanceRecords(
        clubId: widget.clubId,
        eventIds: attendanceHistoryIds(data.events, kstNow()),
      );
      if (mounted) setState(() => _records = records);
    } catch (error) {
      if (!mounted) return;
      if (_data == null) {
        setState(() => _message = attendanceErrorText(error));
      } else {
        // 모임은 보이는데 출석 기록만 못 읽은 경우입니다.
        await showMoaError(context, StateError(attendanceErrorText(error)));
      }
    }
  }

  Future<void> _push(String route, Object arguments) async {
    await Navigator.pushNamed(context, route, arguments: arguments);
    if (mounted) await _load();
  }

  MeetingArgs _meetingArgs(HomeData data, ClubEvent? event) {
    return MeetingArgs(
      clubId: widget.clubId,
      eventId: event?.id,
      role: data.role,
    );
  }

  Future<void> _openNotices() async {
    final data = _data;
    if (data == null) return;
    await showNoticeSheet(context, data.notices);
    await widget.deps.clubs.markNoticesRead(data.club.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: data == null
          ? Center(
              child: _message == null
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_message!, textAlign: TextAlign.center),
                    ),
            )
          : SafeArea(bottom: false, child: _body(data)),
      bottomNavigationBar: MoaBottomNav(
        selected: MoaTab.attendance,
        onSelected: (tab) {
          if (tab == MoaTab.home) goClubHome(context, widget.clubId);
          if (tab == MoaTab.reservation) {
            Navigator.pushNamed(
              context,
              AppRoutes.places,
              arguments: PlaceFlowArgs(clubId: widget.clubId),
            );
          }
          if (tab == MoaTab.myPage) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.myPage,
              arguments: ClubArgs(widget.clubId),
            );
          }
        },
      ),
    );
  }

  Widget _body(HomeData data) {
    final now = kstNow();
    final uid = data.user.id;
    final current = currentAttendanceEvent(data.events, now);
    final rate = attendanceRateFor(
      userId: uid,
      events: semesterMeetings(data.events, semesterOf(now)),
      records: _records,
      now: now,
    );
    final recent = recentAttendanceEvents(data.events, now);
    final canManage = ClubAccess.showsSettings(data.role);
    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        ClubTopBar(
          club: data.club,
          hasUnread: data.hasUnread,
          showSettings: canManage,
          onClub: () => goClubHome(context, widget.clubId),
          onNotices: _openNotices,
          onSettings: () =>
              _push(AppRoutes.clubSettings, ClubArgs(widget.clubId)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ATTENDANCE',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: AppColors.muted,
                ),
              ),
              const Text(
                'QR 출석',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'QR 한 번이면 출석 끝. 대리 출석 걱정도 없어요.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  letterSpacing: -0.4,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 10),
              _Hero(
                event: current,
                checked: current == null ? 0 : _checked(current),
                attended:
                    current != null &&
                    recordOf(_records[current.id], uid) != null,
                onManage: canManage && current != null
                    ? () => _push(
                        AppRoutes.attendanceManage,
                        _meetingArgs(data, current),
                      )
                    : null,
                onScan: () => _push(
                  AppRoutes.attendanceScan,
                  _meetingArgs(data, current),
                ),
              ),
              const SizedBox(height: 10),
              _RateCard(
                rate: rate,
                onTap: () =>
                    _push(AppRoutes.attendanceRates, ClubArgs(widget.clubId)),
              ),
              const SizedBox(height: 10),
              const AttendanceSectionTitle('최근 일정'),
              const SizedBox(height: 10),
              if (recent.isEmpty)
                const MoaEmptyCard(
                  title: '아직 일정이 없어요',
                  body: '모임이 생기면 출석 기록을 여기에 모아둘게요.',
                  icon: Icons.event_available_outlined,
                )
              else
                AttendanceCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < recent.length; i++)
                        _ScheduleRow(
                          event: recent[i],
                          now: now,
                          checked: _checked(recent[i]),
                          mine: recordOf(_records[recent[i].id], uid),
                          target: recent[i].attendeeIds.contains(uid),
                          last: i == recent.length - 1,
                          onTap: () => _push(
                            AppRoutes.meetingDetail,
                            _meetingArgs(data, recent[i]),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  int _checked(ClubEvent event) {
    final records = _records[event.id];
    if (records == null) return event.checkedInCount;
    return presentRecords(event, records).length;
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.event,
    required this.checked,
    required this.attended,
    required this.onManage,
    required this.onScan,
  });

  final ClubEvent? event;
  final int checked;
  final bool attended;
  final VoidCallback? onManage;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final event = this.event;
    final start = event?.startsAt;
    final open = event != null && event.attendanceOpen;
    final status = event == null
        ? '출석할 모임을 기다리고 있어요'
        : attended
        ? '출석을 마쳤어요'
        : open
        ? '지금 출석할 수 있어요'
        : '아직 출석 전이에요';
    final where = [
      if (start != null) formatDayLabel(start),
      if (event != null && event.place.isNotEmpty) event.place,
    ].join(' · ');
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -24,
            top: 44,
            child: AttendanceIcon('hero_star'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(23, 33, 23, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 22,
                  child: Row(
                    children: [
                      if (open && !attended) ...[
                        const LiveDot(),
                        const SizedBox(width: 5),
                      ],
                      Expanded(
                        child: Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: -0.4,
                            color: AppColors.onHero,
                          ),
                        ),
                      ),
                      if (start != null) _Pill('${formatHm(start)} 시작'),
                    ],
                  ),
                ),
                const SizedBox(height: 14.5),
                Text(
                  event?.title ?? '예정된 모임이 없어요',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 26 / 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.2,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 11.7),
                Text(
                  event == null
                      ? '모임이 열리면 여기에서 출석할 수 있어요'
                      : (where.isEmpty ? event.schedule : where),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 14 / 12,
                    letterSpacing: -0.4,
                    color: AppColors.onHero,
                  ),
                ),
                const SizedBox(height: 19.1),
                const Divider(
                  height: 0.635,
                  thickness: 0.635,
                  color: Color(0x24FFFFFF),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 13,
                  child: event == null
                      ? null
                      : Row(
                          children: [
                            const Text('출석', style: _bottomStyle),
                            const SizedBox(width: 5),
                            Text(
                              '$checked / ${event.attendeeCount}명',
                              style: _bottomStyle.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.heroAccent,
                              ),
                            ),
                            const Spacer(),
                            if (onManage != null)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onManage,
                                child: Row(
                                  children: [
                                    Text(
                                      '출석 관리',
                                      style: _bottomStyle.copyWith(
                                        letterSpacing: 0,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const AttendanceIcon('chevron_white'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 18.9),
                AttendanceButton(
                  label: 'QR 스캔으로 출석하기',
                  icon: 'scan',
                  tone: AttendanceButtonTone.white,
                  onPressed: onScan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _bottomStyle = TextStyle(
    fontSize: 11,
    height: 13 / 11,
    letterSpacing: -0.4,
    color: AppColors.onHero,
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          height: 1.2,
          letterSpacing: -0.4,
          color: AppColors.onHero,
        ),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.rate, required this.onTap});

  final AttendanceRate rate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = rate.percent;
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: AppColors.chip),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.6, vertical: 18.6),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.taskGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const AttendanceIcon('chart'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      percent == null ? '내 출석률 -' : '내 출석률 $percent%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7.8),
                    Text(
                      percent == null
                          ? '이번 학기 출석 기록이 아직 없어요'
                          : '이번 학기 모임 ${rate.total}회 중 ${rate.attended}회 출석',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '구성원별 보기',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.8,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: 12),
              const HomeIcon('chevron'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.event,
    required this.now,
    required this.checked,
    required this.mine,
    required this.target,
    required this.last,
    required this.onTap,
  });

  final ClubEvent event;
  final DateTime now;
  final int checked;
  final AttendanceRecord? mine;
  final bool target;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = event.startsAt!;
    final past = isPastMeeting(event, now);
    final dateColor = past ? const Color(0xFF9AA297) : AppColors.primary;
    final (caption, badge) = _state(start, past);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: last ? null : attendanceRowBorder),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 50,
              decoration: BoxDecoration(
                color: past ? AppColors.roleGrayBg : const Color(0xFFEEF3E7),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${start.month}월',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      color: dateColor,
                    ),
                  ),
                  const SizedBox(height: 1.25),
                  Text(
                    '${start.day}',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: dateColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: -0.4,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            badge,
          ],
        ),
      ),
    );
  }

  (String, AttendanceBadge) _state(DateTime start, bool past) {
    final when = isSameDay(start, now)
        ? '오늘 ${formatClock(start)}'
        : formatWeekdayClock(start);
    if (event.attendanceOpen) {
      return (
        '$when · $checked / ${event.attendeeCount}명',
        const AttendanceBadge(label: '진행 중', tone: AttendanceBadgeTone.open),
      );
    }
    final record = mine;
    if (record != null) {
      return (
        '${formatHm(record.checkedAt)} ${record.isManual ? '수동 출석' : 'QR 출석'}',
        AttendanceBadge(
          label: record.isManual ? '수동 출석' : '출석',
          tone: record.isManual
              ? AttendanceBadgeTone.manual
              : AttendanceBadgeTone.present,
        ),
      );
    }
    if (!past) {
      return (
        [when, if (event.place.isNotEmpty) event.place].join(' · '),
        const AttendanceBadge(label: '예정', tone: AttendanceBadgeTone.neutral),
      );
    }
    if (!target) {
      return (
        '참석 대상이 아니었어요',
        const AttendanceBadge(label: '완료', tone: AttendanceBadgeTone.neutral),
      );
    }
    return (
      '출석 기록 없음',
      const AttendanceBadge(label: '결석', tone: AttendanceBadgeTone.absent),
    );
  }
}
