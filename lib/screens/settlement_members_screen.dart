import 'package:flutter/material.dart';
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

class SettlementMembersScreen extends StatefulWidget {
  const SettlementMembersScreen({
    super.key,
    required this.deps,
    required this.args,
  });

  final MoaDependencies deps;
  final SettlementArgs args;

  @override
  State<SettlementMembersScreen> createState() =>
      _SettlementMembersScreenState();
}

class _SettlementMembersScreenState extends State<SettlementMembersScreen> {
  SettlementDetailData? _data;
  String _filter = SettlementShareFilter.all;
  String? _message;
  bool _busy = false;

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
        allShares: true,
      );
      if (!mounted) return;
      if (!canManageBooks(data.role)) {
        Navigator.pop(context);
        return;
      }
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

  Future<void> _complete(SettlementShare share) async {
    final uid = widget.deps.auth.currentUid;
    final settlement = _data?.settlement;
    if (uid == null || settlement == null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.confirmSettlementShare(
        clubId: widget.args.clubId,
        settlementId: settlement.id,
        userId: share.userId,
        actorId: uid,
      );
      await _load();
    } catch (error) {
      if (mounted) showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remind(int open) async {
    final uid = widget.deps.auth.currentUid;
    final settlement = _data?.settlement;
    if (uid == null || settlement == null || open == 0 || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.remindUnsettled(
        clubId: widget.args.clubId,
        settlementId: settlement.id,
        actorId: uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('미정산 알림을 보냈어요.')));
      }
    } catch (error) {
      if (mounted) showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
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
    final shares = settlement.shares;
    final paid = shares
        .where((share) => share.status == SettlementShareStatus.paid)
        .length;
    final reported = shares
        .where((share) => share.status == SettlementShareStatus.reported)
        .length;
    final unpaid = shares
        .where((share) => share.status == SettlementShareStatus.unpaid)
        .length;
    final open = reported + unpaid;
    final visible = filterSettlementShares(shares, _filter);
    final total = settlement.personalTotal;
    final ratio = total <= 0
        ? 0.0
        : (settlement.collectedAmount / total).clamp(0.0, 1.0);
    final percent = total <= 0
        ? 0
        : ((settlement.collectedAmount / total) * 100).round();
    return Column(
      children: [
        const SettlementAppBar(title: '정산 현황'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: AppColors.chip),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settlement.title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF657260),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatGrouped(settlement.collectedAmount),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            ' / ${formatWon(settlement.personalTotal)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
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
                    const SizedBox(height: 8),
                    Text(
                      '입금 완료 $paid명 · 확인 대기 $reported명 · 미입금 $unpaid명',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccountingSegmentBar(
                items: [
                  (SettlementShareFilter.all, '전체 ${shares.length}'),
                  (SettlementShareFilter.paid, '완료 $paid'),
                  (SettlementShareFilter.open, '미정산 $open'),
                ],
                selected: _filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: AppColors.chip),
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < visible.length; index++)
                      _MemberRow(
                        share: visible[index],
                        index: index,
                        bordered: index < visible.length - 1,
                        onComplete:
                            visible[index].status ==
                                SettlementShareStatus.reported
                            ? () => _complete(visible[index])
                            : null,
                      ),
                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          '해당하는 구성원이 없어요.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SettlementBottomButton(
          label: '미정산 $open명에게 알림 보내기',
          onPressed: open == 0 || _busy ? null : () => _remind(open),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.share,
    required this.index,
    required this.bordered,
    this.onComplete,
  });

  final SettlementShare share;
  final int index;
  final bool bordered;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColor(index),
              shape: BoxShape.circle,
            ),
            child: Text(
              share.initial,
              style: const TextStyle(fontSize: 12, color: Color(0xFF53634A)),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.userName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${share.attendanceLabel} · ${formatWon(share.amount)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          if (onComplete != null)
            Material(
              color: const Color(0xFFEAF1E0),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onComplete,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    '완료 처리',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _label,
                style: TextStyle(
                  fontSize: 10,
                  color: _foreground,
                  letterSpacing: -0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String get _label => switch (share.status) {
    SettlementShareStatus.paid => '완료',
    SettlementShareStatus.reported => '확인 대기',
    _ => '미입금',
  };

  Color get _background => switch (share.status) {
    SettlementShareStatus.paid => const Color(0xFFF0F4EB),
    SettlementShareStatus.reported => const Color(0xFFFFF1DC),
    _ => const Color(0xFFF7EDE8),
  };

  Color get _foreground => switch (share.status) {
    SettlementShareStatus.paid => const Color(0xFF5F7B4E),
    SettlementShareStatus.reported => AppColors.copper,
    _ => const Color(0xFFC37550),
  };
}
