import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

class MeetingDetailScreen extends StatefulWidget {
  const MeetingDetailScreen({super.key, required this.deps, required this.args});

  final MoaDependencies deps;
  final MeetingArgs args;

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  ClubEvent? _event;
  String _clubName = '';
  List<ClubMember> _members = const [];
  String? _message;
  StreamSubscription<List<AttendanceRecord>>? _liveSub;

  /// 실시간 출석 기록입니다. 아직 못 받았거나 읽을 수 없으면 null이고,
  /// 그때는 모임 문서에 적힌 출석 수를 보여 줍니다.
  List<AttendanceRecord>? _live;

  bool get _canManage => ClubAccess.showsSettings(widget.args.role);

  @override
  void initState() {
    super.initState();
    _load();
    final id = widget.args.eventId;
    if (id != null) {
      _liveSub = widget.deps.clubs.watchAttendance(clubId: widget.args.clubId, eventId: id).listen(
        (records) {
          if (mounted) setState(() => _live = records);
        },
        onError: (Object _) {},
      );
    }
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.args.eventId;
    final uid = widget.deps.auth.currentUid;
    if (id == null || uid == null) return;
    try {
      final event = await widget.deps.clubs.loadEvent(clubId: widget.args.clubId, eventId: id);
      final desk = await widget.deps.clubs.loadDesk(uid: uid, clubId: widget.args.clubId);
      if (!mounted) return;
      setState(() {
        _event = event;
        _clubName = desk.club.name;
        _members = desk.members;
        _message = null;
      });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _manage() async {
    final event = _event;
    if (event == null) return;
    final action = await showModalBottomSheet<_ManageAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      barrierColor: AppColors.dim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => _ManageSheet(
        event: event,
        onStatus: (status) async {
          await widget.deps.clubs.setMeetingStatus(clubId: widget.args.clubId, eventId: event.id, status: status);
          await _load();
        },
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _ManageAction.edit:
        await Navigator.pushNamed(
          context,
          AppRoutes.meetingEdit,
          arguments: MeetingArgs(clubId: widget.args.clubId, eventId: event.id, role: widget.args.role),
        );
        await _load();
      case _ManageAction.people:
        await _openPeople(event);
      case _ManageAction.delete:
        await widget.deps.clubs.deleteMeeting(clubId: widget.args.clubId, eventId: event.id);
        if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _openPeople(ClubEvent event) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.meetingAttendees,
      arguments: MeetingArgs(
        clubId: widget.args.clubId,
        eventId: event.id,
        role: widget.args.role,
        selectedIds: event.attendeeIds,
      ),
    );
    await _load();
  }

  /// 운영진은 '명단 보기'에서 출석 관리로, 아래 버튼에서 QR 출석 코드로 갑니다.
  Future<void> _openAttendance(String route, ClubEvent event) async {
    await Navigator.pushNamed(
      context,
      route,
      arguments: MeetingArgs(clubId: widget.args.clubId, eventId: event.id, role: widget.args.role),
    );
    await _load();
  }

  void _openQr(ClubEvent event) {
    if (event.status == '완료') {
      showMoaError(context, StateError('완료된 모임은 QR 출석을 열 수 없어요. 출석 관리의 출석자 명단에서 직접 처리해 주세요.'));
      return;
    }
    _openAttendance(AppRoutes.attendanceQr, event);
  }

  void _roster(ClubEvent event) {
    final ids = event.attendeeIds.toSet();
    final names = [
      for (final member in _members)
        if (ids.contains(member.userId) && member.userName.isNotEmpty) member.userName,
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      barrierColor: AppColors.dim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('참석 명단', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (names.isEmpty)
                Text(
                  event.attendeeSummary.isEmpty ? '참석자가 없어요' : event.attendeeSummary,
                  style: const TextStyle(color: AppColors.muted),
                )
              else
                for (final name in names)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final total = event == null ? 0 : event.attendeeCount;
    final live = _live;
    final checked = event == null ? 0 : (live == null ? event.checkedInCount : presentRecords(event, live).length);
    final remaining = total - checked < 0 ? 0 : total - checked;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: event == null
            ? Center(child: _message == null ? const CircularProgressIndicator(color: AppColors.primary) : Text(_message!))
            : Column(
                children: [
                  MoaPageHeader(
                    title: '모임 상세',
                    trailing: _canManage ? IconButton(onPressed: _manage, icon: const Icon(Icons.more_horiz)) : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      children: [
                        _DetailHero(event: event, clubName: _clubName),
                        const SizedBox(height: 12),
                        _InfoCard(rows: [
                          ('일시', event.startsAt == null ? event.schedule : formatMeetingWhen(event.startsAt!, event.endsAt)),
                          ('장소', event.place.isEmpty ? '-' : event.place),
                          if (event.supplies.isNotEmpty) ('준비물', event.supplies),
                        ]),
                        const SizedBox(height: 18),
                        _SectionHead(
                          title: '참석자 ${event.attendeeCount}명',
                          action: _canManage ? '인원 설정' : null,
                          onAction: _canManage ? () => _openPeople(event) : null,
                        ),
                        const SizedBox(height: 10),
                        _Panel(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: _AvatarLine(event: event),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionHead(
                          title: '출석 현황',
                          action: '명단 보기',
                          onAction: () => _canManage ? _openAttendance(AppRoutes.attendanceManage, event) : _roster(event),
                        ),
                        const SizedBox(height: 10),
                        _Panel(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        text: '$checked',
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1),
                                        children: [
                                          TextSpan(
                                            text: ' /$total명',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.muted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    const LiveCaption('실시간'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                AttendanceProgress(value: total == 0 ? 0 : checked / total),
                                const SizedBox(height: 10),
                                Text(
                                  'QR 출석 $checked명 · 아직 $remaining명이 출석하지 않았어요',
                                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _SectionHead(title: '모임 회비', action: '정산 보기'),
                        const SizedBox(height: 10),
                        _InfoCard(rows: [
                          ('참가비', event.feeAmount == null ? '없음' : '${formatWon(event.feeAmount!)} / 1인'),
                          (
                            '납부 현황',
                            event.feeAmount == null
                                ? '-'
                                : '${event.feePaidCount} / $total명${event.feeDueAt == null ? '' : ' · ${formatShortDay(event.feeDueAt!)}까지'}',
                          ),
                        ]),
                      ],
                    ),
                  ),
                  if (_canManage)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: MoaPrimaryButton(label: 'QR 출석 코드 띄우기', icon: Icons.qr_code_2, onPressed: () => _openQr(event)),
                    ),
                ],
              ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.event, required this.clubName});

  final ClubEvent event;
  final String clubName;

  @override
  Widget build(BuildContext context) {
    final status = _statusBadge(event);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeetingArtBanner(event: event, clubName: clubName),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Badge(label: meetingClubLabel(clubName), background: const Color(0xFFEAF0E4), foreground: AppColors.primary),
                    const Spacer(),
                    _Badge(label: status.$1, background: status.$2, foreground: status.$3),
                  ],
                ),
                const SizedBox(height: 10),
                Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(event.description, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _statusBadge(ClubEvent event) {
    final status = event.status;
    if (event.attendanceOpen || status == '진행 중') {
      return ('진행 중', AppColors.peach, AppColors.copper);
    }
    if (status == '완료') return ('완료', const Color(0xFFEEF0EA), const Color(0xFF7D867A));
    if (status.contains('예약')) return (status, AppColors.peach, AppColors.copper);
    return (status.isEmpty ? '예정' : status, const Color(0xFFEAF0E4), AppColors.primary);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _AvatarLine extends StatelessWidget {
  const _AvatarLine({required this.event});

  final ClubEvent event;

  @override
  Widget build(BuildContext context) {
    final initials = event.attendeeInitials.take(6).toList();
    return Row(
      children: [
        for (var i = 0; i < initials.length; i++)
          Align(
            widthFactor: i == 0 ? 1 : 0.74,
            child: _Dot(text: initials[i], color: avatarColor(i)),
          ),
        if (event.attendeeSummary.isNotEmpty) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.attendeeSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF75816F)),
            ),
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: AppColors.white)),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF53634A))),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.4))),
        if (action != null)
          InkWell(
            onTap: onAction,
            child: Row(
              children: [
                Text(action!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.bud),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: i == rows.length - 1 ? null : const Border(bottom: BorderSide(color: AppColors.chip))),
              child: Row(
                children: [
                  Text(rows[i].$1, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(rows[i].$2, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: child,
    );
  }
}

enum _ManageAction { edit, people, delete }

class _ManageSheet extends StatefulWidget {
  const _ManageSheet({required this.event, required this.onStatus});

  final ClubEvent event;
  final Future<void> Function(String status) onStatus;

  @override
  State<_ManageSheet> createState() => _ManageSheetState();
}

class _ManageSheetState extends State<_ManageSheet> {
  late String _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _status = event.attendanceOpen ? '진행 중' : (event.status.isEmpty ? '예정' : event.status);
  }

  Future<void> _setStatus(String status) async {
    if (_busy || _status == status) return;
    final previous = _status;
    setState(() {
      _status = status;
      _busy = true;
    });
    try {
      await widget.onStatus(status);
    } catch (error) {
      if (mounted) setState(() => _status = previous);
      if (mounted) await showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFD5DDD0), borderRadius: BorderRadius.all(Radius.circular(4))),
              child: SizedBox(width: 34, height: 4),
            ),
          ),
          Row(
            children: [
              const Expanded(child: Text('모임 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Text('운영진만 볼 수 있는 메뉴예요.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          const Text('모임 상태', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFFE7EEE3), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                for (final label in ['예정', '진행 중', '완료'])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setStatus(label),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _status == label ? AppColors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(label, style: TextStyle(fontWeight: _status == label ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Panel(
            child: Column(
              children: [
                _SheetRow(title: '모임 정보 수정', subtitle: '이름 · 날짜 · 장소 · 회비', onTap: () => Navigator.pop(context, _ManageAction.edit)),
                _SheetRow(
                  title: '참석 인원 설정',
                  subtitle: '${widget.event.attendeeCount}명',
                  onTap: () => Navigator.pop(context, _ManageAction.people),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, _ManageAction.delete),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.dangerSolid,
                backgroundColor: AppColors.dangerBg,
                side: const BorderSide(color: AppColors.dangerBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('모임 삭제하기'),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('삭제하면 이 모임의 출석 · 회비 기록도 함께 사라져요.', style: TextStyle(fontSize: 11, color: AppColors.muted))),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.title, required this.subtitle, required this.onTap, this.last = false});

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.chip))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.bud),
          ],
        ),
      ),
    );
  }
}
