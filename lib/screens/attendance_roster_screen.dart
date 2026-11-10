import 'package:flutter/material.dart';
import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/view_models/meeting_attendance_feed.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';

enum _RosterFilter { all, present, absent }

class _RosterEntry {
  const _RosterEntry({required this.userId, required this.name, this.record});

  final String userId;
  final String name;
  final AttendanceRecord? record;

  String get initial =>
      name.isEmpty ? '모' : String.fromCharCode(name.runes.first);
}

class AttendanceRosterScreen extends StatefulWidget {
  const AttendanceRosterScreen({
    super.key,
    required this.deps,
    required this.args,
  });

  final MoaDependencies deps;
  final MeetingArgs args;

  @override
  State<AttendanceRosterScreen> createState() => _AttendanceRosterScreenState();
}

class _AttendanceRosterScreenState extends State<AttendanceRosterScreen> {
  late final MeetingAttendanceFeed _feed = MeetingAttendanceFeed(
    clubs: widget.deps.clubs,
    clubId: widget.args.clubId,
    eventId: widget.args.eventId!,
  );
  ClubDesk? _desk;
  _RosterFilter _filter = _RosterFilter.all;
  String _query = '';

  bool get _canManage => ClubAccess.showsSettings(widget.args.role);

  @override
  void initState() {
    super.initState();
    _loadDesk();
  }

  @override
  void dispose() {
    _feed.dispose();
    super.dispose();
  }

  Future<void> _loadDesk() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final desk = await widget.deps.clubs.loadDesk(
        uid: uid,
        clubId: widget.args.clubId,
      );
      if (mounted) setState(() => _desk = desk);
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    }
  }

  /// 출석한 사람을 출석한 순서로 먼저, 그 뒤에 미출석자를 놓습니다.
  List<_RosterEntry> _entries(ClubEvent event) {
    final names = {
      for (final member in _desk?.members ?? const <ClubMember>[])
        member.userId: member.userName,
    };
    final records = {
      for (final record in _feed.records) record.userId: record,
    };
    final entries = [
      for (final id in event.attendeeIds)
        _RosterEntry(
          userId: id,
          name: names[id] ?? records[id]?.userName ?? '이름 없음',
          record: records[id],
        ),
    ];
    final present = entries.where((entry) => entry.record != null).toList()
      ..sort((a, b) => a.record!.checkedAt.compareTo(b.record!.checkedAt));
    final absent = entries.where((entry) => entry.record == null);
    return [...present, ...absent];
  }

  Future<void> _edit(_RosterEntry entry) async {
    final desk = _desk;
    final uid = widget.deps.auth.currentUid;
    if (desk == null || uid == null) return;
    final actorName = desk.user.name.trim().isEmpty
        ? desk.user.displayNickname
        : desk.user.name;
    final reason = await showAttendanceSheet<String>(
      context,
      builder: (context) => _EditSheet(
        name: entry.name,
        actorLine: '$actorName(${ClubAccess.label(desk.myRole)})',
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await widget.deps.clubs.markAttendanceManually(
        clubId: widget.args.clubId,
        eventId: widget.args.eventId!,
        userId: entry.userId,
        userName: entry.name,
        actorId: uid,
        actorName: actorName,
        reason: reason,
      );
    } catch (error) {
      if (mounted) {
        await showMoaError(context, StateError(attendanceErrorText(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AttendanceAppBar(title: '출석자 명단'),
            Expanded(
              child: ListenableBuilder(
                listenable: _feed,
                builder: (context, _) {
                  final event = _feed.event;
                  if (event == null || _desk == null) {
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
    final entries = _entries(event);
    final presentCount = entries.where((entry) => entry.record != null).length;
    final query = _query.trim();
    final visible = entries.where((entry) {
      final matchesFilter = switch (_filter) {
        _RosterFilter.all => true,
        _RosterFilter.present => entry.record != null,
        _RosterFilter.absent => entry.record == null,
      };
      return matchesFilter && (query.isEmpty || entry.name.contains(query));
    }).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 44),
      children: [
        _Segmented(
          selected: _filter,
          labels: {
            _RosterFilter.all: '전체 ${entries.length}',
            _RosterFilter.present: '출석 $presentCount',
            _RosterFilter.absent: '미출석 ${entries.length - presentCount}',
          },
          onSelected: (filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: 13),
        _SearchField(onChanged: (value) => setState(() => _query = value)),
        const SizedBox(height: 13),
        AttendanceCard(
          child: visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    entries.isEmpty ? '참석 대상이 아직 없어요.' : '조건에 맞는 구성원이 없어요.',
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: -0.4,
                      color: AppColors.muted,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < visible.length; i++)
                      AttendanceMemberRow(
                        initial: visible[i].initial,
                        color: attendeeColor(event, visible[i].userId),
                        name: visible[i].name,
                        caption: _caption(visible[i].record),
                        last: i == visible.length - 1,
                        trailing: _trailing(visible[i]),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 13),
        const AttendanceInfoNote(
          icon: 'history',
          text: '수동으로 바꾼 출석은 변경 내역이 기록으로 남아요.',
        ),
      ],
    );
  }

  String _caption(AttendanceRecord? record) {
    if (record == null) return '아직 출석하지 않았어요';
    return '${formatHm(record.checkedAt)} · ${record.methodLabel}';
  }

  Widget _trailing(_RosterEntry entry) {
    final record = entry.record;
    if (record != null) {
      return record.isManual
          ? const AttendanceBadge(
              label: '수동 출석',
              tone: AttendanceBadgeTone.manual,
            )
          : const AttendanceBadge(
              label: '출석',
              tone: AttendanceBadgeTone.present,
            );
    }
    if (!_canManage) {
      return const AttendanceBadge(
        label: '미출석',
        tone: AttendanceBadgeTone.neutral,
      );
    }
    return Material(
      color: AppColors.soft,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _edit(entry),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            '출석 처리',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.selected,
    required this.labels,
    required this.onSelected,
  });

  final _RosterFilter selected;
  final Map<_RosterFilter, String> labels;
  final ValueChanged<_RosterFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDE3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final filter in _RosterFilter.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(filter),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 9,
                  ),
                  decoration: filter == selected
                      ? BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F243A22),
                              offset: Offset(0, 2),
                              blurRadius: 3,
                            ),
                          ],
                        )
                      : null,
                  child: Text(
                    labels[filter] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: -0.4,
                      fontWeight: filter == selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: filter == selected
                          ? AppColors.ink
                          : const Color(0xFF7A8576),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13.6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const AttendanceIcon('search'),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 13,
                letterSpacing: -0.4,
                color: AppColors.ink,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                hintText: '이름으로 검색',
                hintStyle: TextStyle(
                  fontSize: 13,
                  letterSpacing: -0.4,
                  color: Color(0xFFA9B1A3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 저장하면 사유(없으면 빈 문자열)를 돌려주고, 미출석 유지나 닫기는 null을 돌려줍니다.
class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.name, required this.actorLine});

  final String name;
  final String actorLine;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  final _reason = TextEditingController();
  bool _present = true;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = kstNow();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 36),
          child: Text(
            '${widget.name}님 출석 상태',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 7.5),
        const Text(
          'QR로 출석하지 못한 구성원을 직접 처리할 수 있어요.',
          style: TextStyle(
            fontSize: 12,
            height: 1.8,
            letterSpacing: -0.4,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 18),
        _Choice(
          selected: _present,
          title: '출석으로 변경',
          body: '현장에 있었지만 QR을 찍지 못했어요.',
          onTap: () => setState(() => _present = true),
        ),
        const SizedBox(height: 7.5),
        _Choice(
          selected: !_present,
          title: '미출석 유지',
          body: '출석률 계산에 결석으로 들어가요.',
          onTap: () => setState(() => _present = false),
        ),
        const SizedBox(height: 18),
        const Text(
          '사유 (선택)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _reason,
          enabled: _present,
          maxLength: 100,
          style: const TextStyle(fontSize: 13, color: AppColors.ink),
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            hintText: '예: 휴대폰 배터리 방전',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA9B1A3)),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(13.6),
            enabledBorder: _border(AppColors.line),
            disabledBorder: _border(AppColors.line),
            focusedBorder: _border(AppColors.primary),
          ),
        ),
        const SizedBox(height: 18),
        AttendanceButton(
          label: '저장하기',
          height: 44,
          onPressed: () =>
              Navigator.pop(context, _present ? _reason.text.trim() : null),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _present
                ? '변경 내역 · ${widget.actorLine} · ${formatShortDay(now)} ${formatHm(now)} 로 기록돼요'
                : '출석 상태를 바꾸지 않아요',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.8,
              letterSpacing: -0.4,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: BorderSide(color: color),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.3, vertical: 15.3),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF6FAF0) : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.chip,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFC9D2C1),
                ),
              ),
              child: selected
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 10, height: 10),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.6,
                      letterSpacing: -0.4,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
