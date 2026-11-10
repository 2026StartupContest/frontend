import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';
import 'package:image_picker/image_picker.dart';

class MeetingFormScreen extends StatefulWidget {
  const MeetingFormScreen({super.key, required this.deps, required this.args});

  final MoaDependencies deps;
  final MeetingArgs args;

  @override
  State<MeetingFormScreen> createState() => _MeetingFormScreenState();
}

class _MeetingFormScreenState extends State<MeetingFormScreen> {
  static const kinds = ['정기 출사', '뒤풀이', '회의', '기타'];

  final _name = TextEditingController();
  final _place = TextEditingController();
  final _placeFocus = FocusNode();
  String _kind = kinds.first;
  DateTime _date = kstNow();
  TimeOfDay _time = const TimeOfDay(hour: 14, minute: 0);
  bool _charge = false;
  int? _fee;
  DateTime? _due;
  List<String> _attendees = const [];
  String? _eventId;
  int _checkedIn = 0;
  int _feePaid = 0;
  String _status = '예정';
  String _artKicker = '';
  String _artTitle = '';
  String _loadedTitle = '';
  String? _imageUrl;
  Uint8List? _preview;
  ImagePayload? _image;
  bool _busy = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _attendees = widget.args.selectedIds;
    _eventId = widget.args.eventId;
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _place.dispose();
    _placeFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _preview = bytes;
      _image = ImagePayload(bytes: bytes, contentType: 'image/jpeg');
    });
  }

  Future<void> _load() async {
    final id = widget.args.eventId;
    if (id == null) {
      setState(() => _ready = true);
      return;
    }
    try {
      final event = await widget.deps.clubs.loadEvent(clubId: widget.args.clubId, eventId: id);
      if (!mounted) return;
      _name.text = event.title;
      _loadedTitle = event.title;
      _place.text = event.place;
      _kind = kinds.contains(event.badge) ? event.badge : kinds.last;
      _artKicker = event.artKicker;
      _artTitle = event.artTitle;
      _imageUrl = event.imageUrl;
      _date = event.startsAt ?? _date;
      if (event.startsAt != null) {
        _time = TimeOfDay(hour: event.startsAt!.hour, minute: event.startsAt!.minute);
      }
      _charge = event.feeAmount != null;
      _fee = event.feeAmount;
      _due = event.feeDueAt;
      _attendees = event.attendeeIds;
      _checkedIn = event.checkedInCount;
      _feePaid = event.feePaidCount;
      _status = event.status.isEmpty ? '예정' : event.status;
      setState(() => _ready = true);
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    }
  }

  Future<void> _pickPeople() async {
    final picked = await Navigator.pushNamed(
      context,
      AppRoutes.meetingAttendees,
      arguments: MeetingArgs(clubId: widget.args.clubId, role: widget.args.role, selectedIds: _attendees),
    );
    if (picked is List<String> && mounted) setState(() => _attendees = picked);
  }

  Future<void> _save() async {
    final title = _name.text.trim();
    if (title.isEmpty) {
      await showMoaError(context, StateError('모임 이름을 입력해 주세요.'));
      return;
    }
    final start = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    setState(() => _busy = true);
    try {
      final keepArt = _artTitle.isNotEmpty && _artTitle != _loadedTitle;
      final savedId = await widget.deps.clubs.saveMeeting(
        clubId: widget.args.clubId,
        image: _image,
        event: ClubEvent(
          id: _eventId ?? '',
          badge: _kind,
          title: title,
          schedule: formatMeetingWhen(start),
          artKicker: meetingKindLabels.contains(_artKicker.trim()) ? '' : _artKicker,
          artTitle: keepArt ? _artTitle : title,
          imageUrl: _imageUrl,
          startsAt: start,
          place: _place.text.trim(),
          status: _status,
          attendeeIds: _attendees,
          checkedInCount: _checkedIn,
          feeAmount: _charge ? _fee : null,
          feeDueAt: _charge ? _due : null,
          feePaidCount: _feePaid,
        ),
      );
      _eventId = savedId;
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            MoaPageHeader(title: _eventId == null ? '새 모임 만들기' : '모임 정보 수정'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  _label('모임 이름'),
                  TextField(controller: _name, decoration: _nameInput()),
                  const SizedBox(height: 16),
                  _label('모임 종류'),
                  Wrap(
                    spacing: 7,
                    children: [
                      for (final kind in kinds)
                        ChoiceChip(
                          label: Text(kind),
                          selected: _kind == kind,
                          onSelected: (_) => setState(() => _kind = kind),
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFEAF0E2),
                          labelStyle: TextStyle(fontSize: 12, color: _kind == kind ? AppColors.white : const Color(0xFF6E7C64)),
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _label('날짜 · 시간'),
                  Row(
                    children: [
                      Expanded(
                        child: _picker(
                          formatPickerDate(_date),
                          () async {
                            final picked = await _pickDate(_date);
                            if (picked != null) setState(() => _date = picked);
                          },
                          icon: Icons.calendar_today_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 130,
                        child: _picker(
                          formatClock(DateTime(2026, 1, 1, _time.hour, _time.minute)),
                          () async {
                            final picked = await _pickTime(_time);
                            if (picked != null) setState(() => _time = picked);
                          },
                          icon: Icons.expand_more,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _label('장소'),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _place, focusNode: _placeFocus, decoration: _input())),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => _placeFocus.requestFocus(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor: const Color(0xFFE7F0E2),
                          minimumSize: const Size(72, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('장소 찾기'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _label('참석 인원'),
                  _picker('구성원 ${_attendees.length}명 선택됨', _pickPeople),
                  const SizedBox(height: 16),
                  _label('모임 회비'),
                  Material(
                    color: AppColors.white,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                      side: const BorderSide(color: AppColors.chip),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('참가비 받기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: const Text('정산과 회비 장부에 자동으로 연결돼요', style: TextStyle(fontSize: 11)),
                            value: _charge,
                            activeThumbColor: AppColors.white,
                            activeTrackColor: AppColors.primary,
                            onChanged: (value) => setState(() => _charge = value),
                          ),
                          if (_charge) ...[
                            _moneyRow('1인 금액', _fee == null ? '입력' : formatWon(_fee!), () async {
                              final next = await _askAmount(_fee);
                              if (next != null) setState(() => _fee = next);
                            }),
                            _moneyRow('납부 기한', _due == null ? '선택' : formatDueLabel(_due!), () async {
                              final picked = await _pickDate(_due ?? _date);
                              if (picked != null) setState(() => _due = picked);
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.infoNote, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: AppColors.infoText),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('모임은 운영진(회장 · 관리자)만 만들 수 있어요.', style: TextStyle(fontSize: 12, color: AppColors.infoText)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: MoaPrimaryButton(label: _eventId == null ? '모임 만들기' : '저장하기', busy: _busy, onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime initial) {
    var value = DateTime(initial.year, initial.month, initial.day);
    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) {
        return Container(
          height: 320,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () => Navigator.pop(context, value),
                  child: const Text('완료'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: value,
                  minimumDate: DateTime(2024),
                  maximumDate: DateTime(2035, 12, 31),
                  onDateTimeChanged: (next) => value = next,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) {
    var value = initial;
    return showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (context) {
        return Container(
          height: 320,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  onPressed: () => Navigator.pop(context, value),
                  child: const Text('완료'),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(2026, 1, 1, initial.hour, initial.minute),
                  onDateTimeChanged: (next) => value = TimeOfDay(hour: next.hour, minute: next.minute),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
  );

  InputDecoration _nameInput() {
    return _input().copyWith(
      suffixIcon: IconButton(
        onPressed: _pickImage,
        icon: _namePhoto(),
      ),
    );
  }

  Widget _namePhoto() {
    if (_preview != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(_preview!, width: 22, height: 22, fit: BoxFit.cover),
      );
    }
    final url = _imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: moaImage(
          url,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.photo_camera_outlined, size: 20, color: AppColors.bud),
        ),
      );
    }
    return const Icon(Icons.photo_camera_outlined, size: 20, color: AppColors.bud);
  }

  InputDecoration _input() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.primary)),
    );
  }

  Widget _picker(String label, VoidCallback onTap, {IconData icon = Icons.chevron_right}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
            Icon(icon, size: 18, color: AppColors.bud),
          ],
        ),
      ),
    );
  }

  Widget _moneyRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6B5A))),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<int?> _askAmount(int? current) async {
    final controller = TextEditingController(text: current?.toString() ?? '');
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('1인 금액'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('저장')),
        ],
      ),
    );
    controller.dispose();
    if (raw == null) return null;
    return parseWon(raw);
  }
}
