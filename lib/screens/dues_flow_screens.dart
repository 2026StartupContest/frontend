import 'package:flutter/material.dart';
import 'package:flutter_proj/core/accounting.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/accounting.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/accounting_chrome.dart';

Future<bool> showDuesRemindSheet(
  BuildContext context, {
  required MoaDependencies deps,
  required AccountingData data,
  required DuesRound round,
}) {
  final unpaid = data.currentPayments.where((payment) => payment.duesId == round.id && payment.status == DuesStatus.unpaid).toList();
  return _openSheet<bool>(
    context,
    title: '미납 알림',
    child: _RemindBody(deps: deps, data: data, round: round, unpaid: unpaid),
  ).then((value) => value ?? false);
}

Future<bool> showDuesConfirmSheet(
  BuildContext context, {
  required MoaDependencies deps,
  required AccountingData data,
  required DuesPayment payment,
}) {
  return _openSheet<bool>(
    context,
    title: '입금 확인',
    child: _ConfirmBody(deps: deps, data: data, payment: payment),
  ).then((value) => value ?? false);
}

Future<bool> showDuesReportSheet(
  BuildContext context, {
  required MoaDependencies deps,
  required AccountingData data,
  required DuesRound round,
  required DuesPayment payment,
}) {
  return _openSheet<bool>(
    context,
    title: '입금 완료 신고',
    child: _ReportBody(deps: deps, data: data, round: round, payment: payment),
  ).then((value) => value ?? false);
}

Future<T?> _openSheet<T>(BuildContext context, {required String title, required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.dim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) {
      final bottom = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: _Handle()),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.ink),
                  ),
                ],
              ),
              child,
            ],
          ),
        ),
      );
    },
  );
}

class _RemindBody extends StatefulWidget {
  const _RemindBody({
    required this.deps,
    required this.data,
    required this.round,
    required this.unpaid,
  });

  final MoaDependencies deps;
  final AccountingData data;
  final DuesRound round;
  final List<DuesPayment> unpaid;

  @override
  State<_RemindBody> createState() => _RemindBodyState();
}

class _RemindBodyState extends State<_RemindBody> {
  late final TextEditingController _body;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final due = widget.round.dueAt;
    final bank = widget.data.club.bankLine;
    final holder = widget.data.club.accountHolder ?? '';
    _body = TextEditingController(
      text: [
        '아직 ${widget.round.title}를 내지 않으셨나요?',
        if (due != null) '${formatDueLabel(due)}까지 ${formatWon(widget.round.amount)}을 입금해 주세요.',
        if (bank != null) '$bank${holder.isEmpty ? '' : ' ($holder)'}',
      ].join(' '),
    );
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.remindUnpaidDues(
        clubId: widget.data.club.id,
        actorId: uid,
        title: '${widget.round.title} 납부 안내',
        body: _body.text,
      );
      if (mounted) Navigator.pop(context, true);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final payment in widget.unpaid)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: accountingChipIdle, borderRadius: BorderRadius.circular(20)),
                child: Text(payment.userName, style: const TextStyle(fontSize: 11, color: accountingChipText, letterSpacing: -0.4)),
              ),
          ],
        ),
        const SizedBox(height: 16),
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
              Text('${widget.round.title} 납부 안내', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
              const SizedBox(height: 8),
              TextField(
                controller: _body,
                maxLines: 4,
                maxLength: 200,
                style: const TextStyle(fontSize: 13, height: 1.5, letterSpacing: -0.4),
                decoration: const InputDecoration(border: InputBorder.none, counterText: '', isCollapsed: true),
              ),
            ],
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(_message!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        AccountingPrimaryButton(
          label: '${widget.unpaid.length}명에게 알림 보내기',
          icon: Icons.notifications_none,
          busy: _busy,
          onPressed: widget.unpaid.isEmpty ? null : _send,
        ),
      ],
    );
  }
}

class _ConfirmBody extends StatefulWidget {
  const _ConfirmBody({required this.deps, required this.data, required this.payment});

  final MoaDependencies deps;
  final AccountingData data;
  final DuesPayment payment;

  @override
  State<_ConfirmBody> createState() => _ConfirmBodyState();
}

class _ConfirmBodyState extends State<_ConfirmBody> {
  bool _busy = false;
  String? _message;

  Future<void> _confirm() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.confirmDuesPayment(
        clubId: widget.data.club.id,
        duesId: widget.payment.duesId,
        userId: widget.payment.userId,
        actorId: uid,
        actorName: widget.data.userName,
        ledgerTitle: '${widget.payment.duesTitle} · ${widget.payment.userName}',
        amount: widget.payment.amount,
      );
      if (mounted) Navigator.pop(context, true);
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
    final payment = widget.payment;
    final when = payment.reportedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFD9E3CB), shape: BoxShape.circle),
              child: Text(payment.initial, style: const TextStyle(fontSize: 14, color: Color(0xFF53634A))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.userName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  const SizedBox(height: 3),
                  Text('${payment.duesTitle} · 입금 완료 신고', style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: -0.4)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(8)),
              child: const Text('확인 대기', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.copper)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: AppColors.chip),
          ),
          child: Column(
            children: [
              _Line('금액', formatWon(payment.amount)),
              _Line('입금자명', payment.depositName ?? ''),
              _Line('신고 시각', when == null ? '방금' : formatNoticeTime(when), last: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const AccountingNote(text: '확인하면 회계 장부에 수입으로 남아요.'),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(_message!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        AccountingPrimaryButton(label: '입금 확인하기', busy: _busy, onPressed: _confirm),
      ],
    );
  }
}

class _ReportBody extends StatefulWidget {
  const _ReportBody({
    required this.deps,
    required this.data,
    required this.round,
    required this.payment,
  });

  final MoaDependencies deps;
  final AccountingData data;
  final DuesRound round;
  final DuesPayment payment;

  @override
  State<_ReportBody> createState() => _ReportBodyState();
}

class _ReportBodyState extends State<_ReportBody> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.reportDuesPayment(
        clubId: widget.data.club.id,
        duesId: widget.round.id,
        userId: uid,
        depositName: _name.text,
      );
      if (mounted) Navigator.pop(context, true);
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
    final bank = [
      if (widget.data.club.bankLine != null) widget.data.club.bankLine!,
      if ((widget.data.club.accountHolder ?? '').isNotEmpty) widget.data.club.accountHolder!,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(color: const Color(0xFFF0F4E9), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.round.title, style: const TextStyle(fontSize: 12, color: AppColors.muted, letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text(formatWon(widget.payment.amount), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1)),
              if (widget.round.dueAt != null) ...[
                const SizedBox(height: 4),
                Text('${formatShortDay(widget.round.dueAt!)}까지', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('입금자명', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
        const SizedBox(height: 9),
        TextField(
          controller: _name,
          style: const TextStyle(fontSize: 13, letterSpacing: -0.4),
          decoration: InputDecoration(
            hintText: '통장에 찍힌 이름',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: accountingFieldBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: accountingFieldBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
        if (bank.isNotEmpty) ...[
          const SizedBox(height: 12),
          AccountingNote(text: bank),
        ],
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(_message!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        AccountingPrimaryButton(label: '신고하기', busy: _busy, onPressed: _send),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.chip, width: 0.6)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.rowLabel, letterSpacing: -0.4)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: -0.4)),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.handle, borderRadius: BorderRadius.circular(2)),
    );
  }
}
