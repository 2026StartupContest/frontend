import 'package:flutter/material.dart';
import 'package:flutter_proj/core/accounting.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/models/accounting.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/screens/dues_flow_screens.dart';
import 'package:flutter_proj/widgets/accounting_chrome.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/club_sheets.dart';
import 'package:flutter_proj/widgets/moa_bottom_nav.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key, required this.deps, required this.args});

  final MoaDependencies deps;
  final AccountingArgs args;

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  AccountingData? _data;
  String? _message;
  late String _segment;
  String _duesFilter = 'all';

  @override
  void initState() {
    super.initState();
    _segment = widget.args.segment == AccountingSegment.ledger
        ? AccountingSegment.ledger
        : AccountingSegment.dues;
    _load();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final data = await widget.deps.clubs.loadAccounting(
        uid: uid,
        clubId: widget.args.clubId,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _message = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _openNotices() async {
    final data = _data;
    if (data == null) return;
    await showNoticeSheet(context, data.notices);
    await widget.deps.clubs.markNoticesRead(data.club.id);
    await _load();
  }

  void _tab(MoaTab tab) {
    final clubId = widget.args.clubId;
    if (tab == MoaTab.settlement) return;
    if (tab == MoaTab.home) {
      goClubHome(context, clubId);
      return;
    }
    if (tab == MoaTab.reservation) {
      Navigator.pushNamed(context, AppRoutes.places, arguments: PlaceFlowArgs(clubId: clubId));
    }
    if (tab == MoaTab.attendance) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.attendance,
        arguments: ClubArgs(clubId),
      );
    }
    if (tab == MoaTab.myPage) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.myPage,
        arguments: ClubArgs(clubId),
      );
    }
  }

  Future<void> _push(String route, Object arguments) async {
    await Navigator.pushNamed(context, route, arguments: arguments);
    await _load();
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
                    onClub: () => goClubHome(context, widget.args.clubId),
                    onNotices: _openNotices,
                    onSettings: () => _push(AppRoutes.clubSettings, ClubArgs(data.club.id)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: _page(data),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: MoaBottomNav(
        selected: MoaTab.settlement,
        onSelected: _tab,
      ),
    );
  }

  Widget _page(AccountingData data) {
    final personal = widget.args.mine || !canManageBooks(data.role);
    final ledger = _segment == AccountingSegment.ledger;
    final title = !ledger && personal ? '내 회비' : '회계';
    final subtitle = ledger
        ? '모든 부원이 함께 확인하는 투명한 장부.'
        : personal
        ? '내가 낸 회비와 남은 회비를 확인해요.'
        : '누가 냈는지, 얼마나 모였는지 한눈에.';
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
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -1),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted, letterSpacing: -0.4)),
        const SizedBox(height: 16),
        AccountingSegmentBar(
          items: const [(AccountingSegment.dues, '회비'), (AccountingSegment.ledger, '회계 장부')],
          selected: _segment,
          onSelected: (value) => setState(() => _segment = value),
        ),
        const SizedBox(height: 16),
        if (ledger)
          _LedgerHome(data: data, onOpen: _push)
        else if (personal)
          _MyDues(
            data: data,
            onReport: (round, payment) async {
              final done = await showDuesReportSheet(
                context,
                deps: widget.deps,
                data: data,
                round: round,
                payment: payment,
              );
              if (done) await _load();
            },
          )
        else
          _DuesManage(
            data: data,
            filter: _duesFilter,
            onFilter: (value) => setState(() => _duesFilter = value),
            onOpen: _push,
            onRemind: () async {
              final round = data.current;
              if (round == null) return;
              final done = await showDuesRemindSheet(context, deps: widget.deps, data: data, round: round);
              if (done) await _load();
            },
            onConfirm: (payment) async {
              final done = await showDuesConfirmSheet(context, deps: widget.deps, data: data, payment: payment);
              if (done) await _load();
            },
          ),
      ],
    );
  }
}

class _GreenHero extends StatelessWidget {
  const _GreenHero({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: ColoredBox(
        color: AppColors.primary,
        child: Stack(
          children: [
            const Positioned(right: -28, top: 28, child: Opacity(opacity: 0.55, child: HomeIcon('hero_mark'))),
            Padding(padding: const EdgeInsets.fromLTRB(23, 28, 23, 20), child: child),
          ],
        ),
      ),
    );
  }
}

class _DuesManage extends StatelessWidget {
  const _DuesManage({
    required this.data,
    required this.filter,
    required this.onFilter,
    required this.onOpen,
    required this.onRemind,
    required this.onConfirm,
  });

  final AccountingData data;
  final String filter;
  final ValueChanged<String> onFilter;
  final Future<void> Function(String route, Object arguments) onOpen;
  final Future<void> Function() onRemind;
  final Future<void> Function(DuesPayment payment) onConfirm;

  @override
  Widget build(BuildContext context) {
    final round = data.current;
    if (round == null) {
      return Column(
        children: [
          const MoaEmptyCard(
            title: '등록된 회비가 없어요',
            body: '이번 달 회비를 만들면 구성원별 납부 상태가 여기에 모여요.',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 12),
          AccountingPrimaryButton(
            label: '회비 설정',
            onPressed: () => onOpen(AppRoutes.duesSettings, ClubArgs(data.club.id)),
          ),
        ],
      );
    }
    final payments = sortDuesPayments(
      filterDuesPayments(
        visibleDuesPayments(
          role: data.role,
          userId: data.userId,
          payments: data.currentPayments,
        ),
        filter,
      ),
    );
    final progress = duesProgress(data.currentPayments);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${round.title} · ${formatWon(round.amount)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            AccountingTinyButton(
              label: '회비 설정',
              onTap: () => onOpen(AppRoutes.duesSettings, ClubArgs(data.club.id)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: AppColors.chip),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('이번 달 회비가 차곡차곡', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatGrouped(progress.collected),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      '/ ${formatWon(progress.expected)}',
                      style: const TextStyle(fontSize: 14, color: AppColors.muted),
                    ),
                  ),
                  const Spacer(),
                  Text('${progress.percent}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.expected == 0 ? 0 : progress.collected / progress.expected,
                  minHeight: 7,
                  backgroundColor: AppColors.track,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.total}명 중 ${progress.paidCount}명 납부 · 확인 대기 ${progress.reportedCount}명 · 미납 ${progress.unpaidCount}명${round.dueAt == null ? '' : ' · 기한 ${formatShortDay(round.dueAt!)}'}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              AccountingPrimaryButton(
                label: '미납자에게 알림 보내기',
                icon: Icons.notifications_none,
                onPressed: progress.unpaidCount == 0 ? null : onRemind,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in const [('all', '전체'), (DuesStatus.paid, '납부 완료'), (DuesStatus.reported, '확인 대기'), (DuesStatus.unpaid, '미납')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AccountingChip(
                    label: item.$2,
                    selected: filter == item.$1,
                    onTap: () => onFilter(item.$1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _WhiteCard(
          children: [
            if (payments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('이 상태의 구성원이 없어요.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              )
            else
              for (var index = 0; index < payments.length; index++)
                _PaymentRow(
                  payment: payments[index],
                  colorIndex: index,
                  showDivider: index != payments.length - 1,
                  onConfirm: payments[index].status == DuesStatus.reported ? () => onConfirm(payments[index]) : null,
                ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => onOpen(
              AppRoutes.accounting,
              AccountingArgs(data.club.id, AccountingSegment.dues, true),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppColors.chip),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.taskCream, borderRadius: BorderRadius.circular(12)),
                    child: const HomeIcon('dues'),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('내 회비 보기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                        SizedBox(height: 4),
                        Text('부원 화면에서는 이 페이지가 먼저 보여요', style: TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: -0.4)),
                      ],
                    ),
                  ),
                  const HomeIcon('chevron'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MyDues extends StatelessWidget {
  const _MyDues({required this.data, required this.onReport});

  final AccountingData data;
  final Future<void> Function(DuesRound round, DuesPayment payment) onReport;

  @override
  Widget build(BuildContext context) {
    final round = data.current;
    final mine = data.myPayments.where((payment) => payment.duesId == round?.id).toList();
    final current = mine.isEmpty ? null : mine.first;
    final year = kstNow().year;
    final paid = paidDuesInYear(data.myPayments, year);
    final unpaid = data.myPayments.where((payment) => payment.status != DuesStatus.paid).toList();
    final unpaidAmount = unpaid.fold<int>(0, (sum, payment) => sum + payment.amount);
    final history = data.myPayments.where((payment) => payment.status == DuesStatus.paid).toList();
    final bank = [
      if (data.club.bankLine != null) data.club.bankLine!,
      if ((data.club.accountHolder ?? '').isNotEmpty) data.club.accountHolder!,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (round == null || current == null)
          const MoaEmptyCard(
            title: '이번 회비가 없어요',
            body: '운영진이 회비를 등록하면 여기에 보여 드려요.',
            icon: Icons.payments_outlined,
          )
        else
          _GreenHero(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(round.title, style: const TextStyle(fontSize: 12, color: AppColors.onHero, letterSpacing: -0.4)),
                    const Spacer(),
                    if (round.dueAt != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(20)),
                        child: Text('${formatShortDay(round.dueAt!)}까지', style: const TextStyle(fontSize: 10, color: AppColors.onHero, letterSpacing: -0.4)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: formatGrouped(current.amount),
                    style: const TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: AppColors.white, letterSpacing: -1.2),
                    children: const [
                      TextSpan(text: '원', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.only(top: 14),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x24FFFFFF)))),
                  child: Row(
                    children: [
                      Text.rich(
                        TextSpan(
                          text: '상태  ',
                          style: const TextStyle(fontSize: 11, color: AppColors.onHero, letterSpacing: -0.4),
                          children: [TextSpan(text: duesStatusLabel(current.status), style: const TextStyle(fontWeight: FontWeight.w700))],
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          bank.isEmpty ? '계좌 정보가 아직 없어요' : bank,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.onHero, letterSpacing: -0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AccountingPrimaryButton(
                  label: '입금 완료 신고하기',
                  icon: Icons.check,
                  onDark: true,
                  onPressed: current.status == DuesStatus.unpaid ? () => onReport(round, current) : null,
                ),
              ],
            ),
          ),
        const SizedBox(height: 22),
        const Text('납부 내역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
        const SizedBox(height: 10),
        _WhiteCard(
          children: [
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('아직 납부한 회비가 없어요.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              )
            else
              for (var index = 0; index < history.length; index++)
                _HistoryRow(payment: history[index], showDivider: index != history.length - 1),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SummaryTile(label: '올해 낸 회비', value: formatWon(paid))),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryTile(
                label: '미납',
                value: unpaid.isEmpty ? '없음' : '${unpaid.length}건 · ${formatWon(unpaidAmount)}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LedgerHome extends StatelessWidget {
  const _LedgerHome({required this.data, required this.onOpen});

  final AccountingData data;
  final Future<void> Function(String route, Object arguments) onOpen;

  @override
  Widget build(BuildContext context) {
    final now = kstNow();
    final balance = ledgerBalance(data.entries);
    final month = monthLedgerTotals(data.entries, now);
    final recent = data.entries.take(4).toList();
    final latest = data.entries.isEmpty ? null : (data.entries.first.createdAt ?? data.entries.first.occurredAt);
    final canRecord = canRecordLedger(data.role);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GreenHero(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('우리 동아리 공용 잔액', style: TextStyle(fontSize: 12, color: AppColors.onHero, letterSpacing: -0.4)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(20)),
                    child: const Text('부원 전체 공개', style: TextStyle(fontSize: 10, color: AppColors.onHero, letterSpacing: -0.4)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  text: formatGrouped(balance),
                  style: const TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: AppColors.white, letterSpacing: -1.2),
                  children: const [
                    TextSpan(text: '원', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x24FFFFFF)))),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        latest == null ? '아직 기록이 없어요' : '마지막 업데이트 · ${formatNoticeTime(latest, now)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.onHero, letterSpacing: -0.4),
                      ),
                    ),
                    const Text('기초 잔액 + 수입 − 지출', style: TextStyle(fontSize: 11, color: AppColors.onHero, letterSpacing: -0.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _SummaryTile(label: '${now.month}월 총수입', value: '+${formatWon(month.income)}', valueColor: AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(child: _SummaryTile(label: '${now.month}월 총지출', value: '−${formatWon(month.expense)}')),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text('최근 거래', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
            ),
            InkWell(
              onTap: () => onOpen(AppRoutes.ledgerAll, ClubArgs(data.club.id)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('전체 거래', style: TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: -0.4)),
                  SizedBox(width: 2),
                  HomeIcon('chevron_small'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _WhiteCard(
          children: [
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('아직 거래가 없어요.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              )
            else
              for (var index = 0; index < recent.length; index++)
                _LedgerRow(
                  entry: recent[index],
                  showDivider: index != recent.length - 1,
                  onTap: () => onOpen(AppRoutes.ledgerDetail, LedgerEntryArgs(clubId: data.club.id, entryId: recent[index].id)),
                ),
          ],
        ),
        const SizedBox(height: 14),
        AccountingPrimaryButton(
          label: '수입 · 지출 기록하기',
          icon: Icons.add,
          onPressed: canRecord ? () => onOpen(AppRoutes.ledgerEntry, LedgerEntryArgs(clubId: data.club.id)) : null,
        ),
        const SizedBox(height: 10),
        AccountingNote(
          text: canRecord
              ? '장부를 고치면 수정 이력이 남아서 모든 부원이 확인할 수 있어요.'
              : '수입과 지출 기록은 운영진만 남길 수 있어요.',
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.colorIndex,
    required this.showDivider,
    this.onConfirm,
  });

  final DuesPayment payment;
  final int colorIndex;
  final bool showDivider;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.chip, width: 0.6)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: avatarColor(colorIndex), shape: BoxShape.circle),
            child: Text(payment.initial, style: const TextStyle(fontSize: 12, color: Color(0xFF53634A))),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                const SizedBox(height: 3),
                Text('${payment.duesTitle} · ${formatWon(payment.amount)}', style: const TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: -0.4)),
              ],
            ),
          ),
          if (onConfirm != null)
            AccountingTinyButton(label: '입금 확인', onTap: onConfirm!)
          else
            _StatusBadge(status: payment.status),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.payment, required this.showDivider});

  final DuesPayment payment;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final when = payment.confirmedAt ?? payment.dueAt;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.chip, width: 0.6)) : null,
      ),
      child: Row(
        children: [
          const _IconBox(iconName: 'dues'),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.duesTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                const SizedBox(height: 3),
                Text(
                  when == null ? '납부 · 운영진 확인 완료' : '${formatShortDay(when)} 납부 · 운영진 확인 완료',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: -0.4),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatWon(payment.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
              const SizedBox(height: 3),
              const Text('납부 완료', style: TextStyle(fontSize: 10, color: AppColors.presentText, letterSpacing: -0.4)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.showDivider, required this.onTap});

  final LedgerEntry entry;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sign = entry.income ? '+' : '−';
    final note = entry.memo.isEmpty ? entry.category : entry.memo;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider ? const Border(bottom: BorderSide(color: AppColors.chip, width: 0.6)) : null,
        ),
        child: Row(
          children: [
            _IconBox(iconName: entry.income ? 'activity_in' : 'activity_out'),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                  const SizedBox(height: 3),
                  Text(
                    '${formatShortDay(entry.occurredAt)} · ${entry.income ? '수입' : '지출'}',
                    style: const TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: -0.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${formatWon(entry.amount)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: entry.income ? AppColors.primary : AppColors.ink),
                ),
                const SizedBox(height: 3),
                Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: -0.4)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(children: children),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.ink)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final paid = status == DuesStatus.paid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: paid ? AppColors.presentBg : AppColors.unpaidBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        duesStatusLabel(status),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: paid ? AppColors.presentText : AppColors.unpaidText),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.iconName});

  final String iconName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFFEDF1E8), borderRadius: BorderRadius.circular(12)),
      child: HomeIcon(iconName),
    );
  }
}
