import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_proj/core/accounting.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/core/won_input_formatter.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/models/accounting.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/widgets/accounting_chrome.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class LedgerTransactionsScreen extends StatefulWidget {
  const LedgerTransactionsScreen({super.key, required this.deps, required this.clubId});

  final MoaDependencies deps;
  final String clubId;

  @override
  State<LedgerTransactionsScreen> createState() => _LedgerTransactionsScreenState();
}

class _LedgerTransactionsScreenState extends State<LedgerTransactionsScreen> {
  List<LedgerEntry> _entries = [];
  String _range = 'quarter';
  String _kind = 'all';
  DateTime? _start;
  DateTime? _end;
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
      final data = await widget.deps.clubs.loadAccounting(uid: uid, clubId: widget.clubId);
      if (!mounted) return;
      setState(() => _entries = data.entries);
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _pickRange() async {
    final now = kstNow();
    final start = await showDatePicker(
      context: context,
      helpText: '시작일',
      initialDate: _start ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      helpText: '종료일',
      initialDate: _end ?? start,
      firstDate: start,
      lastDate: DateTime(2100),
    );
    if (end == null) return;
    setState(() {
      _range = 'custom';
      _start = start;
      _end = end;
    });
  }

  Future<void> _copyVisible(List<LedgerEntry> shown) async {
    final lines = [
      for (final entry in shown)
        '${formatPickerDate(entry.occurredAt)}  ${entry.income ? '+' : '−'}${formatWon(entry.amount)}  ${entry.title}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('보이는 거래를 복사했어요.')));
  }

  @override
  Widget build(BuildContext context) {
    final now = kstNow();
    final shown = filterLedgerEntries(
      entries: _entries,
      range: _range,
      kind: _kind,
      now: now,
      customStart: _start,
      customEnd: _end,
    );
    final months = <DateTime, List<LedgerEntry>>{};
    for (final entry in shown) {
      final key = DateTime(entry.occurredAt.year, entry.occurredAt.month);
      months.putIfAbsent(key, () => []).add(entry);
    }
    final keys = months.keys.toList()..sort((a, b) => b.compareTo(a));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          children: [
            SizedBox(
              height: 70,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(22),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink)),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      '전체 거래',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.6),
                    ),
                  ),
                  InkWell(
                    onTap: shown.isEmpty ? null : () => _copyVisible(shown),
                    borderRadius: BorderRadius.circular(22),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(child: SvgPicture(SvgAssetLoader('assets/accounting/download.svg'))),
                    ),
                  ),
                ],
              ),
            ),
            if (_message != null) Text(_message!),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final item in const [('month', '이번 달'), ('quarter', '최근 3개월'), ('year', '올해')])
                  AccountingChip(label: item.$2, selected: _range == item.$1, onTap: () => setState(() => _range = item.$1)),
                AccountingChip(
                  label: '직접 선택',
                  selected: _range == 'custom',
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickRange,
                ),
              ],
            ),
            const SizedBox(height: 13),
            AccountingSegmentBar(
              items: const [('all', '전체'), (LedgerKind.income, '수입'), (LedgerKind.expense, '지출')],
              selected: _kind,
              onSelected: (value) => setState(() => _kind = value),
            ),
            const SizedBox(height: 16),
            if (shown.isEmpty)
              const MoaEmptyCard(title: '거래가 없어요', body: '이 기간에 남은 기록이 없어요.', icon: Icons.receipt_long_outlined)
            else
              for (final month in keys) ...[
                _MonthHead(month: month, entries: months[month]!),
                const SizedBox(height: 8),
                _MonthCard(
                  entries: months[month]!,
                  onOpen: (entry) => Navigator.pushNamed(
                    context,
                    AppRoutes.ledgerDetail,
                    arguments: LedgerEntryArgs(clubId: widget.clubId, entryId: entry.id),
                  ).then((_) => _load()),
                ),
                const SizedBox(height: 16),
              ],
          ],
        ),
      ),
    );
  }
}

class _MonthHead extends StatelessWidget {
  const _MonthHead({required this.month, required this.entries});

  final DateTime month;
  final List<LedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final income = entries.where((entry) => entry.income).fold<int>(0, (sum, entry) => sum + entry.amount);
    final expense = entries.where((entry) => !entry.income).fold<int>(0, (sum, entry) => sum + entry.amount);
    final label = month.year == kstNow().year ? '${month.month}월' : '${month.year}년 ${month.month}월';
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
        const Spacer(),
        Text(
          '+${formatWon(income)} / −${formatWon(expense)}',
          style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: -0.4),
        ),
      ],
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.entries, required this.onOpen});

  final List<LedgerEntry> entries;
  final ValueChanged<LedgerEntry> onOpen;

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
          for (var index = 0; index < entries.length; index++)
            _TxRow(entry: entries[index], showDivider: index != entries.length - 1, onTap: () => onOpen(entries[index])),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.entry, required this.showDivider, required this.onTap});

  final LedgerEntry entry;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final day = '${entry.occurredAt.month.toString().padLeft(2, '0')}.${entry.occurredAt.day.toString().padLeft(2, '0')}';
    final kindLabel = entry.income && entry.title.contains('회비') ? '회비 수입' : entry.category;
    final note = (entry.receiptUrl ?? '').isNotEmpty
        ? '영수증 있음'
        : entry.income
        ? '입금 확인'
        : (entry.memo.isEmpty ? entry.category : entry.memo);
    final sign = entry.income ? '+' : '−';
    return InkWell(
      onTap: onTap,
      child: Container(
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
              decoration: BoxDecoration(color: const Color(0xFFEDF1E8), borderRadius: BorderRadius.circular(12)),
              child: SvgPicture(SvgAssetLoader(_txIcon(entry))),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('$day · $kindLabel', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign${formatWon(entry.amount)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: entry.income ? AppColors.primary : AppColors.ink),
                ),
                const SizedBox(height: 3),
                Text(note, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _txIcon(LedgerEntry entry) {
  if (entry.income && entry.title.contains('회비')) return 'assets/accounting/tx_dues.svg';
  return switch (entry.category) {
    '물품 구매' => 'assets/accounting/tx_goods.svg',
    '모임 지원' => 'assets/accounting/tx_meet.svg',
    '활동비' => 'assets/accounting/tx_activity.svg',
    _ => entry.income ? 'assets/accounting/tx_dues.svg' : 'assets/accounting/tx_place.svg',
  };
}

class LedgerEntryScreen extends StatefulWidget {
  const LedgerEntryScreen({super.key, required this.deps, required this.args});

  final MoaDependencies deps;
  final LedgerEntryArgs args;

  @override
  State<LedgerEntryScreen> createState() => _LedgerEntryScreenState();
}

class _LedgerEntryScreenState extends State<LedgerEntryScreen> {
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _memo = TextEditingController();
  String _kind = LedgerKind.expense;
  String _category = ledgerCategories.first;
  DateTime _date = kstNow();
  ImagePayload? _receipt;
  bool _ready = false;
  bool _busy = false;
  String? _message;
  String _actorName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final data = await widget.deps.clubs.loadAccounting(uid: uid, clubId: widget.args.clubId);
      if (!canRecordLedger(data.role)) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final existing = data.entries.where((entry) => entry.id == widget.args.entryId).firstOrNull;
      if (!mounted) return;
      setState(() {
        _actorName = data.userName;
        if (existing != null) {
          _kind = existing.kind;
          _amount.text = formatGrouped(existing.amount);
          _title.text = existing.title;
          _memo.text = existing.memo;
          _category = ledgerCategories.contains(existing.category) ? existing.category : ledgerCategories.last;
          _date = existing.occurredAt;
        }
        _ready = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    }
  }


  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickReceipt() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _receipt = ImagePayload(bytes: bytes, contentType: 'image/jpeg'));
  }

  Future<void> _save() async {
    final uid = widget.deps.auth.currentUid;
    final amount = parseWon(_amount.text);
    if (uid == null || amount == null) {
      setState(() => _message = '금액을 입력해 주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.saveLedgerEntry(
        clubId: widget.args.clubId,
        actorId: uid,
        actorName: _actorName,
        entryId: widget.args.entryId,
        kind: _kind,
        amount: amount,
        title: _title.text,
        occurredAt: _date,
        category: _category,
        memo: _memo.text,
        receipt: _receipt,
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
    final editing = widget.args.entryId != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: !_ready
            ? Center(child: _message == null ? const CircularProgressIndicator(color: AppColors.primary) : Text(_message!))
            : Column(
                children: [
                  _EntryBar(title: editing ? '거래 수정' : '장부에 기록하기'),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      children: [
                        AccountingSegmentBar(
                          items: const [(LedgerKind.expense, '지출'), (LedgerKind.income, '수입')],
                          selected: _kind,
                          onSelected: (value) => setState(() => _kind = value),
                        ),
                        const SizedBox(height: 18),
                        const _FieldLabel('금액'),
                        TextField(
                          controller: _amount,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [WonInputFormatter()],
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
                        const _FieldLabel('사용처'),
                        TextField(controller: _title, style: _entryFieldText, decoration: _entryBox()),
                        const SizedBox(height: 18),
                        const _FieldLabel('날짜'),
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
                                Text(formatPickerDate(_date), style: _entryFieldText),
                                const Spacer(),
                                SvgPicture.asset('assets/accounting/calendar.svg'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _FieldLabel('분류'),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            for (final category in ledgerCategories)
                              AccountingChip(label: category, selected: _category == category, onTap: () => setState(() => _category = category)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const _FieldLabel('목적 · 메모 (선택)'),
                        TextField(controller: _memo, style: _entryFieldText, decoration: _entryBox()),
                        const SizedBox(height: 18),
                        const _FieldLabel('영수증 첨부'),
                        Row(
                          children: [
                            _ReceiptThumb(bytes: _receipt?.bytes),
                            const SizedBox(width: 14),
                            _UploadBox(onTap: _pickReceipt),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                '사진 1장 · 지출은\n영수증을 꼭 첨부해 주세요',
                                style: TextStyle(fontSize: 11, height: 1.8, color: AppColors.muted, letterSpacing: -0.4),
                              ),
                            ),
                          ],
                        ),
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
                    child: AccountingPrimaryButton(label: '기록 저장하기', busy: _busy, onPressed: _save),
                  ),
                ],
              ),
      ),
    );
  }
}

const _entryFieldText = TextStyle(fontSize: 13, color: AppColors.ink, letterSpacing: -0.4);

InputDecoration _entryBox() {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: accountingFieldBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: accountingFieldBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.primary)),
  );
}

class _EntryBar extends StatelessWidget {
  const _EntryBar({required this.title});

  final String title;

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
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink)),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.6),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink)),
    );
  }
}

class _ReceiptThumb extends StatelessWidget {
  const _ReceiptThumb({this.bytes});

  final List<int>? bytes;

  @override
  Widget build(BuildContext context) {
    final photo = bytes;
    return Container(
      width: 76,
      height: 76,
      clipBehavior: Clip.antiAlias,
      padding: photo == null ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.chip),
      ),
      child: photo == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Slip(width: double.infinity),
                _Slip(width: 40),
                _Slip(width: double.infinity),
                _Slip(width: 28, color: AppColors.primary),
                _Slip(width: double.infinity),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(Uint8List.fromList(photo), fit: BoxFit.cover),
            ),
    );
  }
}

class _Slip extends StatelessWidget {
  const _Slip({required this.width, this.color = const Color(0xFFDFE5D8)});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        painter: const _DashedRoundPainter(),
        child: const SizedBox(
          width: 76,
          height: 76,
            child: Center(child: SvgPicture(SvgAssetLoader('assets/accounting/plus.svg'))),
        ),
      ),
    );
  }
}

class _DashedRoundPainter extends CustomPainter {
  const _DashedRoundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFFF3F6EE);
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(20));
    canvas.drawRRect(rrect, fill);
    final paint = Paint()
      ..color = const Color(0xFFC5D0BB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LedgerDetailScreen extends StatefulWidget {
  const LedgerDetailScreen({super.key, required this.deps, required this.args});

  final MoaDependencies deps;
  final LedgerEntryArgs args;

  @override
  State<LedgerDetailScreen> createState() => _LedgerDetailScreenState();
}

class _LedgerDetailScreenState extends State<LedgerDetailScreen> {
  LedgerEntry? _entry;
  bool _staff = false;
  bool _busy = false;
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
      final data = await widget.deps.clubs.loadAccounting(uid: uid, clubId: widget.args.clubId);
      final entry = data.entries.where((item) => item.id == widget.args.entryId).firstOrNull;
      if (!mounted) return;
      setState(() {
        _entry = entry;
        _staff = canManageBooks(data.role);
        _message = entry == null ? '거래를 찾지 못했어요.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    // 삭제는 되돌릴 수 없고 잔액에 바로 반영되므로 한 번 더 확인합니다(#32).
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 거래를 삭제할까요?'),
        content: const Text('잔액에 바로 반영돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.deleteLedgerEntry(clubId: widget.args.clubId, entryId: widget.args.entryId!);
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
    final entry = _entry;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const MoaPageHeader(title: '거래 상세'),
            if (entry == null)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(child: _message == null ? const CircularProgressIndicator(color: AppColors.primary) : Text(_message!)),
              )
            else ...[
              Text(
                '${entry.income ? '+' : '−'}${formatWon(entry.amount)}',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: entry.income ? AppColors.primary : AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(entry.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _line('날짜', formatPickerDate(entry.occurredAt)),
              _line('등록자', entry.actorName),
              _line('목적', entry.memo.isEmpty ? entry.category : entry.memo),
              _line('공개 범위', '부원 전체'),
              if (entry.receiptUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(entry.receiptUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 16),
              if (_staff) ...[
                Row(
                  children: [
                    Expanded(
                      child: AccountingOutlineButton(
                        label: '수정',
                        icon: Icons.edit_outlined,
                        onPressed: _busy
                            ? null
                            : () => Navigator.pushNamed(
                                context,
                                AppRoutes.ledgerEntry,
                                arguments: LedgerEntryArgs(clubId: widget.args.clubId, entryId: entry.id),
                              ).then((_) => _load()),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: AccountingOutlineButton(
                        label: '삭제',
                        icon: Icons.delete_outline,
                        danger: true,
                        onPressed: _busy ? null : _delete,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              const Text(
                '수정 · 삭제는 운영진만 할 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              if (_message != null) Text(_message!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

