import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/settlement.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/models/settlement.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/accounting_chrome.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/settlement_chrome.dart';

class SettlementAttendeesScreen extends StatefulWidget {
  const SettlementAttendeesScreen({
    super.key,
    required this.deps,
    required this.args,
  });

  final MoaDependencies deps;
  final SettlementArgs args;

  @override
  State<SettlementAttendeesScreen> createState() =>
      _SettlementAttendeesScreenState();
}

class _Person {
  _Person({required this.id, required this.name, required this.selected});

  final String id;
  final String name;
  bool selected;
}

class _SettlementAttendeesScreenState extends State<SettlementAttendeesScreen> {
  final List<_Person> _people = [];
  Settlement? _settlement;
  SettlementRound? _round;
  ClubEvent? _meeting;
  List<ClubMember> _members = const [];
  bool _loading = true;
  bool _saving = false;
  String? _message;
  bool _loadedFromMeeting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    final settlementId = widget.args.settlementId;
    final roundId = widget.args.roundId;
    if (uid == null || settlementId == null || roundId == null) return;
    try {
      final data = await widget.deps.clubs.loadSettlementDraft(
        uid: uid,
        clubId: widget.args.clubId,
        settlementId: settlementId,
      );
      if (!mounted) return;
      final settlement = data.settlement;
      final round = settlement?.rounds.cast<SettlementRound?>().firstWhere(
        (item) => item!.id == roundId,
        orElse: () => null,
      );
      if (settlement == null || round == null) throw StateError('차수를 찾지 못했어요.');
      final meeting = data.meetings.cast<ClubEvent?>().firstWhere(
        (event) => event!.id == settlement.meetingId,
        orElse: () => null,
      );
      final names = {
        for (final member in data.members) member.userId: member.userName,
      };
      final selected = round.attendeeIds.toSet();
      final ordered = <String>[
        ...?meeting?.attendeeIds,
        ...round.attendeeIds.where(
          (id) => !(meeting?.attendeeIds.contains(id) ?? false),
        ),
      ];
      final seen = <String>{};
      _people
        ..clear()
        ..addAll([
          for (final id in ordered)
            if (seen.add(id))
              _Person(
                id: id,
                name: names[id] ?? '구성원',
                selected: selected.contains(id),
              ),
        ]);
      setState(() {
        _settlement = settlement;
        _round = round;
        _meeting = meeting;
        _members = data.members;
        _loadedFromMeeting = meeting != null && meeting.attendeeIds.isNotEmpty;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  void _loadAttendance() {
    final ids = _meeting?.attendeeIds ?? const <String>[];
    if (ids.isEmpty) {
      showMoaError(context, StateError('불러올 출석 명단이 없어요.'));
      return;
    }
    final names = {
      for (final member in _members) member.userId: member.userName,
    };
    final existing = {for (final person in _people) person.id};
    setState(() {
      for (final person in _people) {
        person.selected = ids.contains(person.id);
      }
      for (final id in ids) {
        if (existing.contains(id)) continue;
        _people.add(_Person(id: id, name: names[id] ?? '구성원', selected: true));
      }
      _loadedFromMeeting = true;
    });
  }

  Future<void> _addPerson() async {
    final listed = _people.map((person) => person.id).toSet();
    final candidates = _members
        .where((member) => !listed.contains(member.userId))
        .toList();
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
                  '인원 추가',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (candidates.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('추가할 구성원이 없어요.'),
                ),
              for (final member in candidates)
                ListTile(
                  title: Text(member.userName),
                  onTap: () => Navigator.pop(context, member),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null) return;
    setState(
      () => _people.add(
        _Person(id: picked.userId, name: picked.userName, selected: true),
      ),
    );
  }

  Future<void> _save() async {
    final round = _round;
    if (round == null || _saving) return;
    final selected = [
      for (final person in _people)
        if (person.selected) person.id,
    ];
    if (selected.isEmpty) {
      showMoaError(context, StateError('참석자를 한 명 이상 골라 주세요.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.deps.clubs.saveRoundAttendees(
        clubId: widget.args.clubId,
        settlementId: widget.args.settlementId!,
        roundId: round.id,
        attendeeIds: selected,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final selected = _people.where((person) => person.selected).length;
    final shares = round == null
        ? const <String, int>{}
        : splitWon(round.amount, [
            for (final person in _people)
              if (person.selected) person.id,
          ]);
    final each = shares.isEmpty
        ? 0
        : shares.values.reduce((a, b) => a < b ? a : b);
    final index = round?.index ?? 1;
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
                  SettlementAppBar(title: '$index차 참석자'),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(color: AppColors.chip),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$selected명 선택',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      selected == 0
                                          ? '참석자를 체크해 주세요'
                                          : '1인 ${formatWon(each)} (${formatWon(round?.amount ?? 0)} ÷ $selected명)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: const Color(0xFFEAF1E0),
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: _loadAttendance,
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      '출석자 불러오기',
                                      style: TextStyle(
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
                        const SizedBox(height: 16),
                        if (_loadedFromMeeting)
                          AccountingNote(
                            text:
                                '모임 출석 명단(${_meeting?.attendeeIds.length ?? 0}명)에서 불러왔어요. $index차에 남은 사람만 체크해 주세요.',
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
                              for (var i = 0; i < _people.length; i++)
                                _row(i, bordered: i < _people.length - 1),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SettlementDashedButton(
                          label: '인원 추가하기',
                          onTap: _addPerson,
                        ),
                      ],
                    ),
                  ),
                  SettlementBottomButton(
                    label: _saving ? '저장 중' : '저장하기',
                    onPressed: _saving ? null : _save,
                    leading: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$selected명',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const TextSpan(
                              text: ' 선택',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _row(int index, {required bool bordered}) {
    final person = _people[index];
    final other = _otherRounds(person.id);
    final subtitle = person.selected
        ? '${_round?.index ?? 1}차 참석'
        : other.isEmpty
        ? '미선택'
        : '${other.join('·')}차만 참석';
    return InkWell(
      onTap: () => setState(() => person.selected = !person.selected),
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
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: person.selected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: person.selected
                      ? AppColors.primary
                      : const Color(0xFFC9D2C1),
                ),
              ),
              child: person.selected
                  ? const Icon(Icons.check, size: 14, color: AppColors.white)
                  : null,
            ),
            const SizedBox(width: 11),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: avatarColor(index),
                shape: BoxShape.circle,
              ),
              child: Text(
                person.name.isEmpty
                    ? '모'
                    : String.fromCharCode(person.name.runes.first),
                style: const TextStyle(fontSize: 12, color: Color(0xFF53634A)),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      letterSpacing: -0.4,
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

  List<int> _otherRounds(String userId) {
    final current = _round?.id;
    return [
      for (final round in _settlement?.rounds ?? const <SettlementRound>[])
        if (round.id != current && round.attendeeIds.contains(userId))
          round.index,
    ];
  }
}
