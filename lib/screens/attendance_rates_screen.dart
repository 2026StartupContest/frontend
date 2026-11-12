import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/view_models/meeting_attendance_feed.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';

class AttendanceRatesScreen extends StatefulWidget {
  const AttendanceRatesScreen({
    super.key,
    required this.deps,
    required this.clubId,
  });

  final MoaDependencies deps;
  final String clubId;

  @override
  State<AttendanceRatesScreen> createState() => _AttendanceRatesScreenState();
}

class _AttendanceRatesScreenState extends State<AttendanceRatesScreen> {
  List<MemberRate>? _rates;
  AttendanceRate _average = const AttendanceRate(attended: 0, total: 0);
  AttendanceRate _previous = const AttendanceRate(attended: 0, total: 0);
  int _meetings = 0;
  bool _highFirst = true;
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
      final clubs = widget.deps.clubs;
      final now = kstNow();
      final (events, desk) = await (
        clubs.loadMeetings(clubId: widget.clubId),
        clubs.loadDesk(uid: uid, clubId: widget.clubId),
      ).wait;
      final records = await clubs.loadAttendanceRecords(
        clubId: widget.clubId,
        eventIds: attendanceHistoryIds(events, now),
      );
      final semester = semesterOf(now);
      List<MemberRate> ratesIn(List<ClubEvent> meetings) => memberRates(
        members: desk.members,
        events: meetings,
        records: records,
        now: now,
      );
      final current = semesterMeetings(events, semester);
      final rates = ratesIn(current);
      if (!mounted) return;
      setState(() {
        _rates = rates;
        _average = averageRate(rates);
        _previous = averageRate(
          ratesIn(semesterMeetings(events, semester.previous)),
        );
        _meetings = countedMeetings(events: current, records: records, now: now);
      });
    } catch (error) {
      if (mounted) setState(() => _message = attendanceErrorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rates = _rates;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AttendanceAppBar(title: '출석률'),
            Expanded(
              child: rates == null
                  ? Center(
                      child: _message == null
                          ? const CircularProgressIndicator(
                              color: AppColors.primary,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _message!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                    )
                  : _body(sortRates(rates, highFirst: _highFirst)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(List<MemberRate> rates) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 44),
      children: [
        _Hero(average: _average, previous: _previous, meetings: _meetings),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                '구성원별 출석률',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _highFirst = !_highFirst),
              child: Row(
                children: [
                  Text(
                    _highFirst ? '출석률 높은 순' : '출석률 낮은 순',
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.8,
                      letterSpacing: -0.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 3),
                  RotatedBox(
                    quarterTurns: _highFirst ? 0 : 2,
                    child: const AttendanceIcon('sort_chevron'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        AttendanceCard(
          child: rates.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    '이번 학기 출석 기록이 아직 없어요.',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: -0.4,
                      color: AppColors.muted,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < rates.length; i++)
                      _RateRow(item: rates[i], last: i == rates.length - 1),
                  ],
                ),
        ),
        const SizedBox(height: 13),
        const AttendanceInfoNote(
          icon: 'chart_note',
          text: '출석률 = 출석한 모임 수 ÷ 참석 대상이었던 모임 수',
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.average,
    required this.previous,
    required this.meetings,
  });

  final AttendanceRate average;
  final AttendanceRate previous;
  final int meetings;

  @override
  Widget build(BuildContext context) {
    final percent = average.percent;
    final before = previous.percent;
    final gap = percent == null || before == null ? null : percent - before;
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
            top: 34,
            child: AttendanceIcon('hero_star'),
          ),
          Padding(
            padding: const EdgeInsets.all(23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '이번 학기 평균 출석률',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: -0.4,
                          color: AppColors.onHero,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '모임 $meetings회',
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          letterSpacing: -0.4,
                          color: AppColors.onHero,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 51,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text.rich(
                      TextSpan(
                        text: percent == null ? '-' : '$percent',
                        style: const TextStyle(
                          fontSize: 31,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                          color: AppColors.white,
                        ),
                        children: const [
                          TextSpan(
                            text: '%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(
                  height: 0.635,
                  thickness: 0.635,
                  color: Color(0x24FFFFFF),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    if (gap == null)
                      const Text('지난 학기 기록이 없어요', style: _bottomStyle)
                    else ...[
                      const Text('지난 학기보다', style: _bottomStyle),
                      const SizedBox(width: 5),
                      Text(
                        '${gap >= 0 ? '+' : '−'}${gap.abs()}%p',
                        style: _bottomStyle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.heroAccent,
                        ),
                      ),
                      const Spacer(),
                      const Text('QR 출석 도입 후', style: _bottomStyle),
                    ],
                  ],
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

class _RateRow extends StatelessWidget {
  const _RateRow({required this.item, required this.last});

  final MemberRate item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final percent = item.rate.percent ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: last ? null : attendanceRowBorder),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              item.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: AttendanceProgress(
              value: percent / 100,
              height: 8,
              color: percent < attendanceLowRate
                  ? AppColors.lowBar
                  : AppColors.primary,
            ),
          ),
          const SizedBox(width: 11),
          SizedBox(
            width: 40,
            child: Text(
              '$percent%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
