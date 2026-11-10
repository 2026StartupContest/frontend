import 'package:flutter/material.dart';
import 'package:flutter_proj/core/accounting.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/accounting.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/accounting_chrome.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DuesSettingsScreen extends StatefulWidget {
  const DuesSettingsScreen({super.key, required this.deps, required this.clubId});

  final MoaDependencies deps;
  final String clubId;

  @override
  State<DuesSettingsScreen> createState() => _DuesSettingsScreenState();
}

class _DuesSettingsScreenState extends State<DuesSettingsScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  DateTime _due = kstNow().add(const Duration(days: 7));
  String _repeat = 'monthly';
  bool _allMembers = false;
  bool _showAll = false;
  final _selected = <String>{};
  List<ClubMember> _members = [];
  bool _ready = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final now = kstNow();
    _title.text = '${now.month}월 회비';
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final data = await widget.deps.clubs.loadAccounting(uid: uid, clubId: widget.clubId);
      if (!canManageBooks(data.role)) {
        if (mounted) Navigator.pop(context);
        return;
      }
      if (!mounted) return;
      final round = data.current;
      setState(() {
        _members = data.members;
        _selected.addAll(data.members.map((member) => member.userId));
        if (round != null) {
          _title.text = round.title;
          _amount.text = formatGrouped(round.amount);
          if (round.dueAt != null) _due = round.dueAt!;
          _repeat = round.repeat == 'once' ? 'once' : 'monthly';
          _allMembers = round.target != 'selected';
          if (round.target == 'selected') {
            _selected
              ..clear()
              ..addAll(round.targetIds);
          }
        }
        _ready = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _setAmount(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final next = digits.isEmpty ? '' : formatGrouped(int.parse(digits));
    if (next == _amount.text) return;
    _amount.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _due = picked);
  }

  List<DuesTarget> get _targets {
    final chosen = _allMembers ? _members : _members.where((member) => _selected.contains(member.userId));
    return [for (final member in chosen) DuesTarget(userId: member.userId, userName: member.userName)];
  }

  Future<void> _save() async {
    final uid = widget.deps.auth.currentUid;
    final amount = parseWon(_amount.text);
    if (uid == null || amount == null) {
      setState(() => _message = '금액을 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.deps.clubs.registerDues(
        clubId: widget.clubId,
        actorId: uid,
        title: _title.text,
        amount: amount,
        dueAt: _due,
        repeat: _repeat,
        allMembers: _allMembers,
        targets: _targets,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final targets = _targets;
    final visible = _showAll ? _members : _members.take(5).toList();
    final hidden = _members.length - visible.length;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _Bar(),
            if (!_ready)
              Expanded(
                child: Center(
                  child: _message == null
                      ? const CircularProgressIndicator(color: AppColors.primary)
                      : Text(_message!, textAlign: TextAlign.center),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                  children: [
                    const _Label('회비 이름'),
                    const SizedBox(height: 9),
                    TextField(
                      controller: _title,
                      style: _fieldText,
                      decoration: _boxDecoration(),
                    ),
                    const SizedBox(height: 18),
                    const _Label('금액'),
                    const SizedBox(height: 9),
                    TextField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      onChanged: _setAmount,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1, color: AppColors.ink),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: '0',
                        hintStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1, color: Color(0xFFC9D2C1)),
                        suffixText: '원',
                        suffixStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.muted),
                        contentPadding: EdgeInsets.only(top: 6, bottom: 12),
                        border: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 1.9)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 1.9)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 1.9)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _Label('납부 기한'),
                    const SizedBox(height: 9),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: accountingFieldBorder),
                        ),
                        child: Row(
                          children: [
                            Text(formatPickerDate(_due), style: _fieldText),
                            const Spacer(),
                            SvgPicture.asset('assets/accounting/calendar.svg'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _Label('반복'),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      children: [
                        AccountingChip(label: '매달 자동 등록', selected: _repeat == 'monthly', onTap: () => setState(() => _repeat = 'monthly')),
                        AccountingChip(label: '이번 한 번만', selected: _repeat == 'once', onTap: () => setState(() => _repeat = 'once')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _Label('납부 대상'),
                    const SizedBox(height: 9),
                    _ChoiceCard(
                      selected: _allMembers,
                      title: '전체 구성원 (${_members.length}명)',
                      onTap: () => setState(() => _allMembers = true),
                    ),
                    const SizedBox(height: 9),
                    _ChoiceCard(
                      selected: !_allMembers,
                      title: '일부만 선택 (${targets.length}명)',
                      subtitle: '휴학 중인 구성원은 빼 두었어요',
                      onTap: () => setState(() => _allMembers = false),
                    ),
                    if (!_allMembers) ...[
                      const SizedBox(height: 9),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(color: AppColors.chip),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          children: [
                            for (var index = 0; index < visible.length; index++)
                              _MemberRow(
                                member: visible[index],
                                colorIndex: _members.indexOf(visible[index]),
                                checked: _selected.contains(visible[index].userId),
                                showDivider: index != visible.length - 1 || hidden > 0,
                                onChanged: (value) {
                                  setState(() {
                                    if (value) {
                                      _selected.add(visible[index].userId);
                                    } else {
                                      _selected.remove(visible[index].userId);
                                    }
                                  });
                                },
                              ),
                            if (hidden > 0)
                              InkWell(
                                onTap: () => setState(() => _showAll = true),
                                child: SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: Text('외 $hidden명 더 보기', style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: -0.4)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              decoration: const BoxDecoration(
                color: Color(0xF2FFFFFF),
                border: Border(top: BorderSide(color: AppColors.chip, width: 0.6)),
              ),
              child: AccountingPrimaryButton(
                label: '${targets.length}명에게 회비 등록하기',
                busy: _busy,
                onPressed: _ready && targets.isNotEmpty ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _fieldText = TextStyle(fontSize: 13, color: AppColors.ink, letterSpacing: -0.4);

InputDecoration _boxDecoration() {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: _boxBorder(accountingFieldBorder),
    enabledBorder: _boxBorder(accountingFieldBorder),
    focusedBorder: _boxBorder(AppColors.primary),
  );
}

OutlineInputBorder _boxBorder(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: BorderSide(color: color),
  );
}

class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(22),
              child: const SizedBox(width: 44, height: 44, child: Center(child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink))),
            ),
            const Expanded(
              child: Text(
                '회비 설정',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink));
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF6FAF0) : AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.primary : AppColors.chip),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RadioMark(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: const TextStyle(fontSize: 11, height: 1.6, color: AppColors.muted, letterSpacing: -0.4)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.primary : const Color(0xFFC9D2C1)),
      ),
      child: selected ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)) : null,
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.colorIndex,
    required this.checked,
    required this.showDivider,
    required this.onChanged,
  });

  final ClubMember member;
  final int colorIndex;
  final bool checked;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider ? const Border(bottom: BorderSide(color: AppColors.chip, width: 0.6)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: checked ? AppColors.primary : const Color(0xFFC9D2C1)),
              ),
              child: checked ? SvgPicture.asset('assets/accounting/check.svg') : null,
            ),
            const SizedBox(width: 11),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: avatarColor(colorIndex), shape: BoxShape.circle),
              child: Text(member.initial, style: const TextStyle(fontSize: 12, color: Color(0xFF53634A))),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                  const SizedBox(height: 3),
                  Text(
                    checked ? '납부 대상' : '휴학 · 제외',
                    style: const TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: -0.4),
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
