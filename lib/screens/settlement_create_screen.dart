import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/settlement_chrome.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettlementCreateScreen extends StatefulWidget {
  const SettlementCreateScreen({
    super.key,
    required this.deps,
    required this.args,
  });

  final MoaDependencies deps;
  final SettlementArgs args;

  @override
  State<SettlementCreateScreen> createState() => _SettlementCreateScreenState();
}

class _SettlementCreateScreenState extends State<SettlementCreateScreen> {
  final _title = TextEditingController();
  final _bankName = TextEditingController();
  final _bankAccount = TextEditingController();
  List<ClubEvent> _meetings = const [];
  List<ClubMember> _members = const [];
  ClubEvent? _meeting;
  ClubMember? _receiver;
  bool _support = false;
  int _supportAmount = 0;
  DateTime _due = DateTime(
    kstNow().year,
    kstNow().month,
    kstNow().day,
  ).add(const Duration(days: 3));
  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _bankName.dispose();
    _bankAccount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final data = await widget.deps.clubs.loadSettlementDraft(
        uid: uid,
        clubId: widget.args.clubId,
        settlementId: widget.args.settlementId,
      );
      if (!mounted) return;
      final settlement = data.settlement;
      _meetings = data.meetings;
      _members = data.members;
      _bankName.text = data.club.bankName ?? '';
      _bankAccount.text = data.club.bankAccount ?? '';
      _receiver = _members.cast<ClubMember?>().firstWhere(
        (member) => member!.userId == data.club.ownerId,
        orElse: () => _members.isEmpty ? null : _members.first,
      );
      if (settlement != null) {
        _title.text = settlement.title;
        _meeting = _meetings.cast<ClubEvent?>().firstWhere(
          (event) => event!.id == settlement.meetingId,
          orElse: () => null,
        );
        _support = settlement.supportAmount > 0;
        _supportAmount = settlement.supportAmount;
        _bankName.text = settlement.bankName;
        _bankAccount.text = settlement.bankAccount;
        _receiver = _members.cast<ClubMember?>().firstWhere(
          (member) => member!.userId == settlement.receiverUserId,
          orElse: () => _receiver,
        );
        if (settlement.dueAt != null) _due = settlement.dueAt!;
      }
      setState(() {
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

  Future<void> _pickMeeting() async {
    final picked = await showModalBottomSheet<ClubEvent>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '연결할 모임',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (_meetings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '연결할 모임이 없어요.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              for (final event in _meetings)
                ListTile(
                  title: Text(event.title),
                  subtitle: Text(_meetingLine(event)),
                  onTap: () => Navigator.pop(context, event),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _meeting = picked;
      if (_title.text.trim().isEmpty) _title.text = picked.title;
      if (picked.startsAt != null) {
        final start = picked.startsAt!;
        _due = DateTime(
          start.year,
          start.month,
          start.day,
        ).add(const Duration(days: 3));
      }
    });
  }

  Future<void> _pickReceiver() async {
    final picked = await showModalBottomSheet<ClubMember>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '입금 받을 사람',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              for (final member in _members)
                ListTile(
                  title: Text(member.userName),
                  onTap: () => Navigator.pop(context, member),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _receiver = picked);
  }

  Future<void> _pickSupport() async {
    final amount = await askSettlementAmount(
      context,
      title: '지원 금액',
      initial: _supportAmount,
    );
    if (amount != null) setState(() => _supportAmount = amount);
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _next() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null || _saving) return;
    setState(() => _saving = true);
    try {
      final id = await widget.deps.clubs.saveSettlementDraft(
        clubId: widget.args.clubId,
        actorId: uid,
        settlementId: widget.args.settlementId,
        title: _title.text,
        meetingId: _meeting?.id ?? '',
        meetingTitle: _meeting?.title ?? '',
        meetingAt: _meeting?.startsAt,
        supportAmount: _support ? _supportAmount : 0,
        receiverUserId: _receiver?.userId ?? '',
        receiverName: _receiver?.userName ?? '',
        bankName: _bankName.text,
        bankAccount: _bankAccount.text,
        dueAt: _due,
      );
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        AppRoutes.settlementRounds,
        arguments: SettlementArgs(clubId: widget.args.clubId, settlementId: id),
      );
    } catch (error) {
      if (mounted) showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const SettlementAppBar(title: '새 정산 만들기'),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                      children: [
                        const SettlementStepper(step: 1),
                        const SizedBox(height: 16),
                        const Text(
                          '어떤 모임을 정산할까요?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const SettlementFieldLabel('정산 이름'),
                        SettlementTextField(controller: _title, hint: '정산 이름'),
                        const SizedBox(height: 16),
                        const SettlementFieldLabel('연결할 모임'),
                        SettlementSelect(
                          value: _meeting == null
                              ? '모임을 골라 주세요'
                              : _meetingLine(_meeting!),
                          onTap: _pickMeeting,
                        ),
                        const SizedBox(height: 18),
                        const SettlementFieldLabel('공용 회비 지원'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(color: AppColors.chip),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '회비에서 일부 지원하기',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            '지원금은 회계 장부에 한 번만 자동 기록돼요',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.muted,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _support,
                                      activeThumbColor: AppColors.white,
                                      activeTrackColor: AppColors.primary,
                                      onChanged: (value) =>
                                          setState(() => _support = value),
                                    ),
                                  ],
                                ),
                              ),
                              if (_support)
                                InkWell(
                                  onTap: _pickSupport,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                          color: AppColors.chip,
                                          width: 0.6,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          '지원 금액',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF5F6B5A),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          formatWon(_supportAmount),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SettlementFieldLabel('받는 사람 (입금 계좌)'),
                        SettlementSelect(
                          value: _accountLine,
                          onTap: _pickReceiver,
                        ),
                        const SizedBox(height: 10),
                        SettlementTextField(controller: _bankName, hint: '은행'),
                        const SizedBox(height: 8),
                        SettlementTextField(
                          controller: _bankAccount,
                          hint: '계좌번호',
                        ),
                        const SizedBox(height: 16),
                        const SettlementFieldLabel('입금 기한'),
                        SettlementSelect(
                          value: formatPickerDate(_due),
                          onTap: _pickDue,
                          icon: SvgPicture.asset(
                            'assets/accounting/calendar.svg',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SettlementBottomButton(
                    label: _saving ? '저장 중' : '다음 · 차수별 금액 입력',
                    onPressed: _saving ? null : _next,
                  ),
                ],
              ),
      ),
    );
  }

  String get _accountLine {
    final name = _receiver?.userName ?? '받는 사람';
    final bank = [
      _bankName.text.trim(),
      _bankAccount.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    if (bank.isEmpty) return name;
    return '$name · $bank';
  }
}

String _meetingLine(ClubEvent event) {
  final when = event.startsAt == null ? '' : formatDayLabel(event.startsAt!);
  final count = event.attendeeIds.isEmpty
      ? event.checkedInCount
      : event.attendeeIds.length;
  final head = [when, event.title].where((part) => part.isNotEmpty).join(' ');
  return '$head · 출석 $count명';
}
