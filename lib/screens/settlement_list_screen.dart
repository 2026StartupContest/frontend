import 'package:flutter/material.dart';
import 'package:flutter_proj/core/accounting.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/settlement.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/settlement.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/club_sheets.dart';
import 'package:flutter_proj/widgets/moa_bottom_nav.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettlementListScreen extends StatefulWidget {
  const SettlementListScreen({
    super.key,
    required this.deps,
    required this.clubId,
  });

  final MoaDependencies deps;
  final String clubId;

  @override
  State<SettlementListScreen> createState() => _SettlementListScreenState();
}

class _SettlementListScreenState extends State<SettlementListScreen> {
  SettlementListData? _data;
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
      final data = await widget.deps.clubs.loadSettlementList(
        uid: uid,
        clubId: widget.clubId,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _message = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message = error.toString().replaceFirst('Bad state: ', ''),
      );
    }
  }

  Future<void> _openNotices() async {
    final data = _data;
    if (data == null) return;
    await showNoticeSheet(context, data.notices);
    await widget.deps.clubs.markNoticesRead(data.club.id);
    await _load();
  }

  Future<void> _push(String route, Object arguments) async {
    await Navigator.pushNamed(context, route, arguments: arguments);
    await _load();
  }

  void _openDetail(Settlement item) {
    _push(
      AppRoutes.settlementDetail,
      SettlementArgs(clubId: widget.clubId, settlementId: item.id),
    );
  }

  void _openMembers(Settlement item) {
    _push(
      AppRoutes.settlementMembers,
      SettlementArgs(clubId: widget.clubId, settlementId: item.id),
    );
  }

  void _continueDraft(Settlement item) {
    _push(
      AppRoutes.settlementRounds,
      SettlementArgs(clubId: widget.clubId, settlementId: item.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: data == null
          ? Center(
              child: _message == null
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_message!, textAlign: TextAlign.center),
                    ),
            )
          : SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  ClubTopBar(
                    club: data.club,
                    hasUnread: data.hasUnread,
                    showSettings: canManageBooks(data.role),
                    onClub: () => goClubHome(context, widget.clubId),
                    onNotices: _openNotices,
                    onSettings: () =>
                        _push(AppRoutes.clubSettings, ClubArgs(data.club.id)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: _page(data),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: MoaBottomNav(
        onSelected: (tab) {
          if (tab == MoaTab.home) goClubHome(context, widget.clubId);
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
            );
          }
          if (tab == MoaTab.settlement) openAccounting(context, widget.clubId);
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

  Widget _page(SettlementListData data) {
    final staff = canManageBooks(data.role);
    final active = data.items.where((item) => !item.isDone).toList();
    final done = data.items.where((item) => item.isDone).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.club.category.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            height: 1.7,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: AppColors.muted,
          ),
        ),
        const Text(
          'N차 정산',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '함께한 만큼, 정확하고 가볍게.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.muted,
            letterSpacing: -0.4,
          ),
        ),
        if (staff) ...[
          const SizedBox(height: 16),
          _CreateButton(
            onPressed: () => _push(
              AppRoutes.settlementCreate,
              SettlementArgs(clubId: data.club.id),
            ),
          ),
        ],
        const _SectionLabel('진행 중'),
        if (active.isEmpty)
          const _EmptyActive()
        else
          for (final item in active) ...[
            _ActiveCard(
              item: item,
              mine: item.shareFor(data.userId)?.amount ?? 0,
              staff: staff,
              onMine: () =>
                  item.isDraft ? _continueDraft(item) : _openDetail(item),
              onMembers: () => _openMembers(item),
            ),
            const SizedBox(height: 10),
          ],
        const _SectionLabel('완료된 정산'),
        if (done.isEmpty)
          const _EmptyDone()
        else
          _DoneCard(items: done, onOpen: _openDetail),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlusIcon(),
              SizedBox(width: 7),
              Text(
                '새 정산 만들기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlusIcon extends StatelessWidget {
  const _PlusIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/settlement/plus.svg');
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    required this.item,
    required this.mine,
    required this.staff,
    required this.onMine,
    required this.onMembers,
  });

  final Settlement item;
  final int mine;
  final bool staff;
  final VoidCallback onMine;
  final VoidCallback onMembers;

  @override
  Widget build(BuildContext context) {
    final total = item.personalTotal;
    final ratio = total <= 0
        ? 0.0
        : (item.collectedAmount / total).clamp(0.0, 1.0);
    final people = item.shareCount > 0
        ? item.shareCount
        : item.participantCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(
                text: item.isDraft ? '작성 중' : '입금 받는 중',
                background: item.isDraft ? AppColors.soft : AppColors.peach,
                foreground: item.isDraft ? AppColors.primary : AppColors.copper,
              ),
              const Spacer(),
              if (!item.isDraft && item.dueAt != null)
                Text(
                  settlementDueCaption(item),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    letterSpacing: -0.4,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            settlementListCaption(item),
            style: const TextStyle(
              fontSize: 11,
              height: 1.8,
              color: AppColors.muted,
              letterSpacing: -0.4,
            ),
          ),
          if (!item.isDraft) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '입금 ${item.paidCount} / $people명',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                Text(
                  '${formatGrouped(item.collectedAmount)} / ${formatWon(item.personalTotal)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(
                value: ratio.toDouble(),
                minHeight: 7,
                backgroundColor: const Color(0xFFEDF0E6),
                color: AppColors.primary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (item.isDraft)
            _CardButton(label: '이어서 작성', filled: true, onTap: onMine)
          else
            Row(
              children: [
                Expanded(
                  child: _CardButton(
                    label: '내 금액 ${formatWon(mine)}',
                    filled: false,
                    onTap: onMine,
                  ),
                ),
                if (staff) ...[
                  const SizedBox(width: 9),
                  Expanded(
                    child: _CardButton(
                      label: '구성원별 현황',
                      filled: true,
                      onTap: onMembers,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primary : const Color(0xFFEAF1E0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: filled ? AppColors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
          letterSpacing: -0.4,
        ),
      ),
    );
  }
}

class _EmptyActive extends StatelessWidget {
  const _EmptyActive();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Badge(text: '진행 중', background: Color(0xFFF0F1EC), foreground: Color(0xFF9AA297)),
          SizedBox(height: 10),
          Text(
            '아직 없습니다',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink),
          ),
          SizedBox(height: 4),
          Text(
            '정산이 시작되면 여기에 보여요.',
            style: TextStyle(fontSize: 11, height: 1.8, color: AppColors.muted, letterSpacing: -0.4),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text('입금 0 / 0명', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.muted)),
              Spacer(),
              Text('0 / 0원', style: TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: -0.4)),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(9)),
            child: LinearProgressIndicator(
              value: 0,
              minHeight: 7,
              backgroundColor: Color(0xFFEDF0E6),
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _QuietButton(label: '내 금액', filled: false)),
              SizedBox(width: 9),
              Expanded(child: _QuietButton(label: '구성원별 현황', filled: true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFD5DDD0) : const Color(0xFFF3F6EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: filled ? AppColors.white : const Color(0xFFB7C3B0)),
      ),
    );
  }
}

class _EmptyDone extends StatelessWidget {
  const _EmptyDone();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFF0F1EC),
                  borderRadius: BorderRadius.all(Radius.circular(13)),
                ),
                child: Center(
                  child: Text(
                    '-',
                    style: TextStyle(fontSize: 16, height: 1.1, fontWeight: FontWeight.w800, color: Color(0xFF9AA297)),
                  ),
                ),
              ),
            ),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('아직 없습니다', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                  SizedBox(height: 3),
                  Text('완료된 정산이 여기에 모여요.', style: TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: -0.4)),
                ],
              ),
            ),
            _Badge(text: '정산 완료', background: Color(0xFFEEF0EA), foreground: Color(0xFF7D867A)),
          ],
        ),
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.items, required this.onOpen});

  final List<Settlement> items;
  final ValueChanged<Settlement> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++)
            _DoneRow(
              item: items[index],
              bordered: index < items.length - 1,
              onTap: () => onOpen(items[index]),
            ),
        ],
      ),
    );
  }
}

class _DoneRow extends StatelessWidget {
  const _DoneRow({
    required this.item,
    required this.bordered,
    required this.onTap,
  });

  final Settlement item;
  final bool bordered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = item.meetingAt ?? item.createdAt ?? item.dueAt;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: bordered
              ? const Border(
                  bottom: BorderSide(color: AppColors.chip, width: 0.6),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1EC),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date == null ? '' : '${date.month}월',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9AA297),
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    date == null ? '-' : '${date.day}',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9AA297),
                      letterSpacing: -0.4,
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
                    item.title,
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
                    settlementDoneSubtitle(item),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            const _Badge(
              text: '정산 완료',
              background: Color(0xFFEEF0EA),
              foreground: Color(0xFF7D867A),
            ),
          ],
        ),
      ),
    );
  }
}
