import 'package:flutter/material.dart';
import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/view_models/meeting_attendance_feed.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';

class AttendanceManageScreen extends StatefulWidget {
  const AttendanceManageScreen({
    super.key,
    required this.deps,
    required this.args,
  });

  final MoaDependencies deps;
  final MeetingArgs args;

  @override
  State<AttendanceManageScreen> createState() => _AttendanceManageScreenState();
}

class _AttendanceManageScreenState extends State<AttendanceManageScreen> {
  static const _recentLimit = 6;

  late final MeetingAttendanceFeed _feed = MeetingAttendanceFeed(
    clubs: widget.deps.clubs,
    clubId: widget.args.clubId,
    eventId: widget.args.eventId!,
  );

  @override
  void dispose() {
    _feed.dispose();
    super.dispose();
  }

  void _open(String route) {
    Navigator.pushNamed(context, route, arguments: widget.args);
  }

  void _openQr(ClubEvent event) {
    if (event.status == '완료') {
      showMoaError(
        context,
        StateError('완료된 모임은 QR 출석을 열 수 없어요. 출석자 명단에서 직접 처리해 주세요.'),
      );
      return;
    }
    _open(AppRoutes.attendanceQr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AttendanceAppBar(title: '출석 관리'),
            Expanded(
              child: ListenableBuilder(
                listenable: _feed,
                builder: (context, _) {
                  final event = _feed.event;
                  if (event == null) {
                    return Center(
                      child: _feed.message == null
                          ? const CircularProgressIndicator(
                              color: AppColors.primary,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _feed.message!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                    );
                  }
                  return _body(event);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(ClubEvent event) {
    final recent = _feed.records.take(_recentLimit).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 17, 24, 41),
      children: [
        AttendanceInfoCard(
          rows: [
            ('모임', event.title, null),
            (
              '일시',
              event.startsAt == null
                  ? (event.schedule.isEmpty ? '-' : event.schedule)
                  : formatMeetingWhen(event.startsAt!),
              null,
            ),
            ('장소', event.place.isEmpty ? '-' : event.place, null),
            ('참석 예정', '${_feed.total}명', null),
          ],
        ),
        const SizedBox(height: 10),
        _LiveCard(feed: _feed),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AttendanceButton(
                label: 'QR 띄우기',
                icon: 'qr_white',
                onPressed: () => _openQr(event),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: AttendanceButton(
                label: '출석자 명단',
                icon: 'people',
                tone: AttendanceButtonTone.soft,
                onPressed: () => _open(AppRoutes.attendanceRoster),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const AttendanceSectionTitle('방금 출석했어요'),
        const SizedBox(height: 10),
        AttendanceCard(
          child: recent.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    '아직 출석한 사람이 없어요.',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: -0.4,
                      color: AppColors.muted,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < recent.length; i++)
                      AttendanceMemberRow(
                        initial: recent[i].initial,
                        color: attendeeColor(event, recent[i].userId),
                        name: recent[i].userName,
                        caption: recent[i].methodLabel,
                        last: i == recent.length - 1,
                        trailing: Text(
                          formatHm(recent[i].checkedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.8,
                            letterSpacing: -0.4,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.feed});

  final MeetingAttendanceFeed feed;

  @override
  Widget build(BuildContext context) {
    return AttendanceCard(
      padding: const EdgeInsets.fromLTRB(19.6, 22.6, 19.6, 19.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  '실시간 출석 현황',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: -0.4,
                    color: Color(0xFF657260),
                  ),
                ),
              ),
              LiveCaption('자동 갱신 중'),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 61.8,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text.rich(
                TextSpan(
                  text: '${feed.checked}',
                  style: const TextStyle(
                    fontSize: 40,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: AppColors.ink,
                  ),
                  children: [
                    TextSpan(
                      text: ' / ${feed.total}명',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          AttendanceProgress(value: feed.progress),
          const SizedBox(height: 8),
          Text(
            '출석률 ${feed.percent}% · 미출석 ${feed.remaining}명',
            style: const TextStyle(
              fontSize: 11,
              height: 1.8,
              letterSpacing: -0.4,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
