import 'package:flutter/material.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/meeting_filter.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/club_sheets.dart';
import 'package:flutter_proj/widgets/moa_bottom_nav.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key, required this.deps, required this.clubId});

  final MoaDependencies deps;
  final String clubId;

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  HomeData? _data;
  String? _message;
  MeetingFilter _filter = MeetingFilter.upcoming;
  late DateTime _focus = DateTime(kstNow().year, kstNow().month, kstNow().day);
  final _scroll = ScrollController();
  final _topKey = GlobalKey();
  final _upcomingKey = GlobalKey();
  final _pastKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

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
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    }
  }

  Future<void> _openNotices() async {
    final data = _data;
    if (data == null) return;
    await showNoticeSheet(context, data.notices);
    await widget.deps.clubs.markNoticesRead(data.club.id);
    await _load();
  }

  void _selectFilter(MeetingFilter filter) {
    setState(() => _filter = filter);
    final key = switch (filter) {
      MeetingFilter.past => _pastKey,
      MeetingFilter.all => _topKey,
      MeetingFilter.upcoming => _upcomingKey,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = key.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 280),
        alignment: 0.02,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final now = kstNow();
    final events = data?.events ?? const <ClubEvent>[];
    final featured = _featured(events);
    final upcoming = events
        .where(
          (event) => !isPastMeeting(event, now) && event.id != featured?.id,
        )
        .toList();
    final past = events
        .where((event) => isPastMeeting(event, now) && event.id != featured?.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: data == null
          ? Center(
              child: _message == null
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : Text(_message!),
            )
          : SafeArea(
              bottom: false,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  ClubTopBar(
                    club: data.club,
                    hasUnread: data.hasUnread,
                    showSettings: ClubAccess.showsSettings(data.role),
                    onClub: () => Navigator.pop(context),
                    onNotices: _openNotices,
                    onSettings: () => Navigator.pushNamed(
                      context,
                      AppRoutes.clubSettings,
                      arguments: ClubArgs(widget.clubId),
                    ),
                  ),
                  Padding(
                    key: _topKey,
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.club.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.6,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                            height: 1.7,
                          ),
                        ),
                        const Text(
                          '우리 모임',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          '같이 모이고, 함께한 순간을 기록해요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            height: 1.7,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              '${_focus.year}년 ${_focus.month}월',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const Spacer(),
                            if (ClubAccess.showsSettings(data.role))
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.meetingEdit,
                                    arguments: MeetingArgs(
                                      clubId: widget.clubId,
                                      role: data.role,
                                    ),
                                  );
                                  await _load();
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('모임 만들기'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  backgroundColor: AppColors.white,
                                  side: const BorderSide(
                                    color: Color(0xFFD9E1D1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity.abs() < 80) return;
                            setState(
                              () => _focus = _focus.add(
                                Duration(days: velocity < 0 ? 7 : -7),
                              ),
                            );
                          },
                          child: _WeekStrip(
                            focus: _focus,
                            onSelect: (day) => setState(() => _focus = day),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _Filters(selected: _filter, onSelected: _selectFilter),
                        const SizedBox(height: 12),
                        if (featured != null)
                          GestureDetector(
                            onTap: () => _openDetail(data.role, featured),
                            child: EventCard(
                              event: featured,
                              clubName: data.club.name,
                            ),
                          )
                        else
                          MoaEmptyCard(
                            title: isSameDay(_focus, kstNow())
                                ? '오늘 일정이 없어요'
                                : '이 날 모임이 없어요',
                            body: '새로 시작해 보세요. 모임을 만들면 여기에 보여 드려요.',
                            icon: Icons.event_available_outlined,
                          ),
                        const SizedBox(height: 22),
                        SectionTitle(key: _upcomingKey, title: '다가오는 모임'),
                        if (upcoming.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _MeetingCard(
                            events: upcoming,
                            past: false,
                            onOpen: (event) => _openDetail(data.role, event),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SectionTitle(key: _pastKey, title: '지난 모임'),
                        if (past.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _MeetingCard(
                            events: past,
                            past: true,
                            onOpen: (event) => _openDetail(data.role, event),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _PlaceBanner(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.places,
                            arguments: PlaceFlowArgs(clubId: widget.clubId),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: MoaBottomNav(
        selected: MoaTab.home,
        onSelected: (tab) {
          if (tab == MoaTab.home) Navigator.pop(context);
          if (tab == MoaTab.reservation) {
            Navigator.pushNamed(
              context,
              AppRoutes.places,
              arguments: PlaceFlowArgs(clubId: widget.clubId),
            );
          }
          if (tab == MoaTab.attendance) {
            Navigator.pushNamed(
              context,
              AppRoutes.attendance,
              arguments: ClubArgs(widget.clubId),
            ).then((_) => _load());
          }
          if (tab == MoaTab.myPage) {
            Navigator.pushNamed(
              context,
              AppRoutes.myPage,
              arguments: ClubArgs(widget.clubId),
            );
          }
        },
      ),
    );
  }

  Future<void> _openDetail(String role, ClubEvent event) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.meetingDetail,
      arguments: MeetingArgs(
        clubId: widget.clubId,
        eventId: event.id,
        role: role,
      ),
    );
    await _load();
  }

  ClubEvent? _featured(List<ClubEvent> events) {
    for (final event in events) {
      final start = event.startsAt;
      if (start != null && isSameDay(start, _focus)) return event;
    }
    return null;
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.focus, required this.onSelect});

  final DateTime focus;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final start = focus.subtract(Duration(days: focus.weekday - 1));
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var index = 0; index < 7; index++)
          _DayCell(
            label: labels[index],
            day: start.add(Duration(days: index)),
            selected: _sameDay(start.add(Duration(days: index)), focus),
            onTap: () =>
                onSelect(DateTime(start.year, start.month, start.day + index)),
          ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? const Color(0xFFC9DBCA) : AppColors.muted,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.white : AppColors.ink,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onSelected});

  final MeetingFilter selected;
  final ValueChanged<MeetingFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (MeetingFilter.upcoming, '다가오는 모임'),
      (MeetingFilter.past, '지난 모임'),
      (MeetingFilter.all, '전체'),
    ];
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final item in items)
          GestureDetector(
            onTap: () => onSelected(item.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected == item.$1
                    ? AppColors.primary
                    : const Color(0xFFEAF0E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.$2,
                style: TextStyle(
                  fontSize: 11,
                  color: selected == item.$1
                      ? AppColors.white
                      : const Color(0xFF6E7C64),
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({
    required this.events,
    required this.past,
    required this.onOpen,
  });

  final List<ClubEvent> events;
  final bool past;
  final ValueChanged<ClubEvent> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(
        children: [
          for (var index = 0; index < events.length; index++)
            _MeetingRow(
              event: events[index],
              past: past,
              bordered: index != events.length - 1,
              onTap: () => onOpen(events[index]),
            ),
        ],
      ),
    );
  }
}

class _MeetingRow extends StatelessWidget {
  const _MeetingRow({
    required this.event,
    required this.past,
    required this.bordered,
    required this.onTap,
  });

  final ClubEvent event;
  final bool past;
  final bool bordered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final start = event.startsAt;
    final badge = _badge(event, past);
    final dateColor = past ? const Color(0xFF9AA297) : AppColors.primary;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: bordered
              ? const Border(bottom: BorderSide(color: AppColors.chip))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: past ? const Color(0xFFF0F1EC) : const Color(0xFFEEF3E7),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    start == null ? '-' : '${start.month}월',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: dateColor,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    start == null ? '-' : '${start.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: dateColor,
                      height: 1.1,
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
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    past ? _pastLine(event) : _upcomingLine(event),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: badge.$2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge.$1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: badge.$3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _upcomingLine(ClubEvent event) {
    final when = event.startsAt == null
        ? event.schedule
        : formatWeekdayClock(event.startsAt!);
    final parts = <String>[
      if (when.isNotEmpty) when,
      if (event.place.isNotEmpty) event.place,
      '참석 ${event.attendeeCount}명',
    ];
    return parts.join(' · ');
  }

  String _pastLine(ClubEvent event) {
    final total = event.attendeeCount;
    final base = '출석 ${event.checkedInCount} / $total명';
    final fee = event.feeAmount;
    if (fee != null && total > 0 && event.feePaidCount < total)
      return '$base · 정산 진행 중';
    return base;
  }

  (String, Color, Color) _badge(ClubEvent event, bool past) {
    if (past) return ('완료', const Color(0xFFEEF0EA), const Color(0xFF7D867A));
    if (event.status.contains('예약'))
      return (event.status, AppColors.peach, AppColors.copper);
    if (event.attendanceOpen)
      return ('출석 진행 중', const Color(0xFFEAF0E4), AppColors.primary);
    if (event.status.isNotEmpty)
      return (event.status, const Color(0xFFEAF0E4), AppColors.primary);
    return ('예정', const Color(0xFFEAF0E4), AppColors.primary);
  }
}

class _PlaceBanner extends StatelessWidget {
  const _PlaceBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E6),
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFFF2DF),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.restaurant_outlined,
                  size: 20,
                  color: AppColors.ink,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '뒤풀이 장소가 필요하세요?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '단체 예약 가능한 곳을 모아봤어요',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9A7D4C)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.bud),
          ],
        ),
      ),
    );
  }
}
