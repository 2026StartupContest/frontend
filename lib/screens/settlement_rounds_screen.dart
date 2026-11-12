import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/settlement.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/settlement_chrome.dart';

class SettlementRoundsScreen extends StatefulWidget {
  const SettlementRoundsScreen({
    super.key,
    required this.deps,
    required this.args,
  });

  final MoaDependencies deps;
  final SettlementArgs args;

  @override
  State<SettlementRoundsScreen> createState() => _SettlementRoundsScreenState();
}

class _SettlementRoundsScreenState extends State<SettlementRoundsScreen> {
  Settlement? _settlement;
  List<SettlementRound> _rounds = const [];
  bool _loading = true;
  bool _busy = false;
  String? _message;

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
      final data = await widget.deps.clubs.loadSettlementDraft(
        uid: uid,
        clubId: widget.args.clubId,
        settlementId: settlementId,
      );
      if (!mounted) return;
      final settlement = data.settlement;
      var rounds = settlement?.rounds ?? const <SettlementRound>[];
      if (rounds.isEmpty && settlement != null) {
        final meeting = data.meetings.cast<dynamic>().where(
          (event) => event.id == settlement.meetingId,
        );
        final event = meeting.isEmpty ? null : meeting.first;
        rounds = [
          SettlementRound(
            id: '',
            index: 1,
            label: '',
            place: event?.place ?? '',
            amount: 0,
            attendeeIds: event == null
                ? const []
                : List<String>.from(event.attendeeIds),
          ),
        ];
      }
      setState(() {
        _settlement = settlement;
        _rounds = rounds;
        _loading = false;
        _message = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<void> _editLabel(int index) async {
    final next = await askSettlementText(
      context,
      title: '차수 이름',
      initial: _rounds[index].label,
    );
    if (next == null) return;
    setState(() => _rounds[index] = _rounds[index].copyWith(label: next));
  }

  Future<void> _editPlace(int index) async {
    final next = await askSettlementText(
      context,
      title: '장소',
      initial: _rounds[index].place,
    );
    if (next == null) return;
    setState(() => _rounds[index] = _rounds[index].copyWith(place: next));
  }

  Future<void> _editAmount(int index) async {
    final next = await askSettlementAmount(
      context,
      title: '총 결제 금액',
      initial: _rounds[index].amount,
    );
    if (next == null) return;
    setState(() => _rounds[index] = _rounds[index].copyWith(amount: next));
  }

  Future<void> _openAttendees(int index) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.saveSettlementRounds(
        clubId: widget.args.clubId,
        settlementId: widget.args.settlementId!,
        rounds: _rounds,
      );
      final fresh = await widget.deps.clubs.loadSettlementDraft(
        uid: widget.deps.auth.currentUid!,
        clubId: widget.args.clubId,
        settlementId: widget.args.settlementId,
      );
      final saved = fresh.settlement?.rounds ?? const <SettlementRound>[];
      if (saved.length <= index) return;
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        AppRoutes.settlementAttendees,
        arguments: SettlementArgs(
          clubId: widget.args.clubId,
          settlementId: widget.args.settlementId,
          roundId: saved[index].id,
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addRound() {
    setState(() {
      _rounds = [
        ..._rounds,
        SettlementRound(
          id: '',
          index: _rounds.length + 1,
          label: '',
          place: '',
          amount: 0,
          attendeeIds: const [],
        ),
      ];
    });
  }

  void _removeRound(int index) {
    if (_rounds.length == 1) {
      showMoaError(context, StateError('차수는 하나 이상 필요해요.'));
      return;
    }
    setState(() => _rounds = [..._rounds]..removeAt(index));
  }

  Future<void> _calculate() async {
    final uid = widget.deps.auth.currentUid;
    final settlementId = widget.args.settlementId;
    if (uid == null || settlementId == null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.saveSettlementRounds(
        clubId: widget.args.clubId,
        settlementId: settlementId,
        rounds: _rounds,
      );
      await widget.deps.clubs.calculateSettlement(
        clubId: widget.args.clubId,
        settlementId: settlementId,
      );
      if (!mounted) return;
      await Navigator.pushReplacementNamed(
        context,
        AppRoutes.settlementDetail,
        arguments: SettlementArgs(
          clubId: widget.args.clubId,
          settlementId: settlementId,
          openConfirm: true,
        ),
      );
    } catch (error) {
      if (mounted) showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final support = _settlement?.supportAmount ?? 0;
    final total = _rounds.fold<int>(
      0,
      (sum, round) => sum + (round.amount < 0 ? 0 : round.amount),
    );
    final personal = total - (support > total ? total : support);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _message != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_message!, textAlign: TextAlign.center),
                ),
              )
            : Column(
                children: [
                  const SettlementAppBar(title: '차수별 금액 입력'),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                      children: [
                        const SettlementStepper(step: 2),
                        const SizedBox(height: 16),
                        const Text(
                          '차수마다 쓴 돈을 입력해 주세요',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '참석자는 차수마다 다르게 고를 수 있어요.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (
                          var index = 0;
                          index < _rounds.length;
                          index++
                        ) ...[
                          _RoundCard(
                            round: _rounds[index],
                            displayIndex: index + 1,
                            onTitle: () => _editLabel(index),
                            onPlace: () => _editPlace(index),
                            onAmount: () => _editAmount(index),
                            onAttendees: () => _openAttendees(index),
                            onDelete: () => _removeRound(index),
                          ),
                          const SizedBox(height: 10),
                        ],
                        SettlementDashedButton(
                          label: '${_rounds.length + 1}차 추가하기',
                          onTap: _addRound,
                        ),
                        const SizedBox(height: 10),
                        _SummaryCard(
                          total: total,
                          support: support > total ? total : support,
                          personal: personal < 0 ? 0 : personal,
                        ),
                      ],
                    ),
                  ),
                  SettlementBottomButton(
                    label: _busy ? '계산 중' : '정산 계산하기',
                    onPressed: _busy ? null : _calculate,
                  ),
                ],
              ),
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({
    required this.round,
    required this.displayIndex,
    required this.onTitle,
    required this.onPlace,
    required this.onAmount,
    required this.onAttendees,
    required this.onDelete,
  });

  final SettlementRound round;
  final int displayIndex;
  final VoidCallback onTitle;
  final VoidCallback onPlace;
  final VoidCallback onAmount;
  final VoidCallback onAttendees;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = round.label.trim().isEmpty
        ? '$displayIndex차'
        : '$displayIndex차 · ${round.label.trim()}';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onTitle,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          _line('장소', round.place.isEmpty ? '장소 입력' : round.place, onPlace),
          _line(
            '총 결제 금액',
            round.amount == 0 ? '금액 입력' : formatWon(round.amount),
            onAmount,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Text(
                  '참석자',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5F6B5A),
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                Material(
                  color: const Color(0xFFEAF1E0),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: onAttendees,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Text(
                        '${round.attendeeIds.length}명 · 변경',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.chip, width: 0.6)),
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.support,
    required this.personal,
  });

  final int total;
  final int support;
  final int personal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(
        children: [
          _row('총 지출', formatWon(total), AppColors.ink),
          _row('회비 지원', '−${formatWon(support)}', AppColors.ink),
          _row(
            '개인 정산 합계',
            formatWon(personal),
            AppColors.primary,
            lined: false,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color, {bool lined = true}) {
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}
