import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_proj/core/accounting.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/settlement.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/settlement.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/accounting_chrome.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/settlement_chrome.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettlementDetailScreen extends StatefulWidget {
  const SettlementDetailScreen({
    super.key,
    required this.deps,
    required this.args,
  });

  final MoaDependencies deps;
  final SettlementArgs args;

  @override
  State<SettlementDetailScreen> createState() => _SettlementDetailScreenState();
}

class _SettlementDetailScreenState extends State<SettlementDetailScreen> {
  SettlementDetailData? _data;
  String? _roundId;
  String? _message;
  bool _askedConfirm = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    final settlementId = widget.args.settlementId;
    if (uid == null || settlementId == null) return;
    try {
      final data = await widget.deps.clubs.loadSettlement(
        uid: uid,
        clubId: widget.args.clubId,
        settlementId: settlementId,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _roundId ??= data.settlement.rounds.isEmpty
            ? null
            : data.settlement.rounds.first.id;
        _message = null;
      });
      if (widget.args.openConfirm &&
          !_askedConfirm &&
          data.settlement.isDraft &&
          canManageBooks(data.role)) {
        _askedConfirm = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _confirm();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message = error.toString().replaceFirst('Bad state: ', ''),
      );
    }
  }

  SettlementRound? get _round {
    final rounds = _data?.settlement.rounds ?? const <SettlementRound>[];
    for (final round in rounds) {
      if (round.id == _roundId) return round;
    }
    return rounds.isEmpty ? null : rounds.first;
  }

  Future<void> _confirm() async {
    final data = _data;
    if (data == null) return;
    final settlement = data.settlement;
    final split = splitSettlement(
      supportAmount: settlement.supportAmount,
      rounds: [
        for (final round in settlement.rounds)
          RoundSplitInput(
            id: round.id,
            index: round.index,
            amount: round.amount,
            attendeeIds: round.attendeeIds,
          ),
      ],
    );
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        final counts = settlement.rounds
            .map((round) => '${round.index}차 ${round.attendeeIds.length}명')
            .join(' · ');
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '정산을 확정할까요?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$counts 기준이에요. 확정하면 구성원에게 개인 분담금을 알림으로 보내요.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.muted,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 14),
              _sheetCard([
                _sheetRow('공용 회비 지원', formatWon(split.supportApplied)),
                _sheetRow('개인 정산 합계', formatWon(split.personalTotal)),
                for (final group in split.groups)
                  _sheetRow(group.label, '${formatWon(group.amount)}씩'),
              ]),
              const SizedBox(height: 16),
              SettlementBottomButton(
                label: '확정하고 구성원에게 알리기',
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
      },
    );
    if (accepted != true || !mounted) return;
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      await widget.deps.clubs.confirmSettlement(
        clubId: widget.args.clubId,
        settlementId: settlement.id,
        actorId: uid,
        actorName: data.userName,
      );
      await _load();
    } catch (error) {
      if (mounted) showMoaError(context, error);
    }
  }

  Future<void> _account() async {
    final data = _data;
    if (data == null) return;
    final settlement = data.settlement;
    final mine = settlement.shareFor(data.userId);
    final canReport =
        settlement.isCollecting &&
        mine != null &&
        mine.status == SettlementShareStatus.unpaid;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '입금 계좌 안내',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '정산을 받는 사람의 계좌예요.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
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
                    Text(
                      [
                        settlement.bankName,
                        settlement.receiverName,
                      ].where((part) => part.trim().isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 13, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            settlement.bankAccount,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: settlement.bankAccount),
                          ),
                          child: const Text(
                            '복사',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '입금액 ${formatWon(mine?.amount ?? 0)} · 입금자명 ${data.userName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (canReport) ...[
                const SizedBox(height: 16),
                SettlementBottomButton(
                  label: '입금했어요',
                  onPressed: () async {
                    Navigator.pop(context);
                    await _report();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _report() async {
    final data = _data;
    final uid = widget.deps.auth.currentUid;
    if (data == null || uid == null) return;
    final controller = TextEditingController(text: data.userName);
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            18,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '입금자명',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SettlementTextField(controller: controller),
              const SizedBox(height: 16),
              SettlementBottomButton(
                label: '신고하기',
                onPressed: () => Navigator.pop(context, controller.text.trim()),
              ),
            ],
          ),
        );
      },
    );
    if (name == null || name.isEmpty || !mounted) return;
    try {
      await widget.deps.clubs.reportSettlementPayment(
        clubId: widget.args.clubId,
        settlementId: data.settlement.id,
        userId: uid,
        depositName: name,
      );
      await _load();
    } catch (error) {
      if (mounted) showMoaError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: data == null
            ? Center(
                child: _message == null
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_message!, textAlign: TextAlign.center),
                      ),
              )
            : _body(data),
      ),
    );
  }

  Widget _body(SettlementDetailData data) {
    final settlement = data.settlement;
    final staff = canManageBooks(data.role);
    final round = _round;
    final mine = settlement.shareFor(data.userId);
    final when = settlement.meetingAt == null
        ? ''
        : _detailDate(settlement.meetingAt!);
    final due = settlement.dueAt == null
        ? ''
        : '기한 ${settlement.dueAt!.month}.${settlement.dueAt!.day}';
    final caption = [
      when,
      '개인 정산',
      due,
    ].where((part) => part.isNotEmpty).join(' · ');
    final breakdown = mine == null
        ? ''
        : [
            for (
              var i = 0;
              i < mine.roundIndexes.length && i < mine.roundAmounts.length;
              i++
            )
              '${mine.roundIndexes[i]}차 ${formatGrouped(mine.roundAmounts[i])}',
          ].join(' + ');
    final pill = _pill(mine, settlement.rounds.length);
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        SettlementAppBar(title: settlement.title),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.8,
                  color: AppColors.muted,
                  letterSpacing: -0.4,
                ),
              ),
              if (settlement.rounds.length > 1) ...[
                const SizedBox(height: 8),
                AccountingSegmentBar(
                  items: [
                    for (final item in settlement.rounds)
                      (item.id, item.heading),
                  ],
                  selected: round?.id ?? '',
                  onSelected: (value) => setState(() => _roundId = value),
                ),
              ],
              const SizedBox(height: 10),
              if (round != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: AppColors.chip),
                  ),
                  child: Column(
                    children: [
                      _moneyRow('총 결제 금액', formatWon(round.amount)),
                      _moneyRow(
                        '공용 회비 지원',
                        '−${formatWon(round.supportApplied)}',
                      ),
                      _moneyRow('정산 대상', '${round.attendeeIds.length}명'),
                      _moneyRow(
                        '1인 분담금',
                        formatWon(round.shareAmount),
                        emphasize: true,
                        lined: false,
                      ),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 18, bottom: 10),
                child: Text(
                  '내가 낼 금액',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(23),
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      right: -24,
                      top: 34,
                      child: Opacity(opacity: 0.9, child: _HeroMark()),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${data.userName}님의 총 분담금',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFDBE8DD),
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            if (pill.isNotEmpty)
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
                                  pill,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFDBE8DD),
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            text: formatGrouped(mine?.amount ?? 0),
                            style: const TextStyle(
                              fontSize: 31,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              letterSpacing: -1.2,
                            ),
                            children: const [
                              TextSpan(
                                text: '원',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(height: 0.6, color: const Color(0x24FFFFFF)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                breakdown,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFDBE8DD),
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _account,
                              child: const Row(
                                children: [
                                  Text(
                                    '계좌 보기',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 14,
                                    color: AppColors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AccountingNote(
                text:
                    '공용 회비 지원 ${formatWon(settlement.supportAmount)}은 장부에 한 번만 기록하고, 나머지 ${formatWon(settlement.personalTotal)}은 개인 정산으로 나눠요.',
              ),
              const SizedBox(height: 12),
              if (settlement.isDraft && staff)
                SettlementBottomButton(label: '정산 확정하기', onPressed: _confirm)
              else
                _action('정산하기', filled: true, onTap: _account),
            ],
          ),
        ),
      ],
    );
  }

  String _detailDate(DateTime date) {
    const weeks = ['월', '화', '수', '목', '금', '토', '일'];
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day (${weeks[date.weekday - 1]})';
  }

  String _pill(SettlementShare? mine, int roundCount) {
    if (mine == null || mine.roundIndexes.isEmpty) return '';
    if (mine.roundIndexes.length == roundCount && roundCount > 1) {
      return '${mine.roundIndexes.map((index) => '$index차').join(' + ')} 참석';
    }
    return mine.attendanceLabel;
  }

  Widget _moneyRow(
    String label,
    String value, {
    bool emphasize = false,
    bool lined = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: lined
            ? const Border(
                bottom: BorderSide(color: AppColors.chip, width: 0.6),
              )
            : null,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5F6B5A),
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 17 : 12,
              fontWeight: FontWeight.w600,
              color: emphasize ? AppColors.primary : AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    String label, {
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? AppColors.primary : const Color(0xFFEAF1E0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Text(
            label,
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

class _HeroMark extends StatelessWidget {
  const _HeroMark();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/settlement/hero.svg');
  }
}

Widget _sheetCard(List<Widget> rows) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: AppColors.chip),
    ),
    child: Column(children: rows),
  );
}

Widget _sheetRow(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.chip, width: 0.6)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5F6B5A),
              letterSpacing: -0.4,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ],
    ),
  );
}
