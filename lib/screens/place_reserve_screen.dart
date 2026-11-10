import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/place_widgets.dart';

class PlaceReserveScreen extends StatefulWidget {
  const PlaceReserveScreen({super.key, required this.args});

  final PlaceFlowArgs args;

  @override
  State<PlaceReserveScreen> createState() => _PlaceReserveScreenState();
}

class _PlaceReserveScreenState extends State<PlaceReserveScreen> {
  final _note = TextEditingController();
  var _date = 1;
  var _time = '19:00';
  var _headcount = 24;
  var _meeting = placeMeetings.first;

  DummyPlace get _place => placeById(widget.args.placeId!);

  @override
  void initState() {
    super.initState();
    _headcount = _headcount.clamp(1, _place.capacity);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _deposit => _headcount * placeDepositPerPerson;

  Future<void> _pickMeeting() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              for (final meeting in placeMeetings)
                ListTile(
                  title: Text(
                    meeting,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, meeting),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _meeting = picked);
  }

  void _next() {
    Navigator.pushNamed(
      context,
      AppRoutes.placeConfirm,
      arguments: PlaceFlowArgs(
        clubId: widget.args.clubId,
        placeId: _place.id,
        draft: PlaceDraft(
          placeId: _place.id,
          dateIndex: _date,
          time: _time,
          headcount: _headcount,
          meeting: _meeting,
          note: _note.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = _place;
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: PlaceBottomBar(
        child: AttendanceButton(
          label: '예약 요청 보내기 · ${formatWon(_deposit)}',
          onPressed: _next,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AttendanceAppBar(title: '예약하기'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  PlacePanel(
                    child: Row(
                      children: [
                        const PlaceMark(size: 54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    place.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  if (place.partner) ...[
                                    const SizedBox(width: 5),
                                    const PlacePartnerBadge(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                place.reserveMeta,
                                style: const TextStyle(
                                  fontSize: 11,
                                  letterSpacing: -0.4,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _Label('날짜'),
                  Row(
                    children: [
                      for (var i = 0; i < placeDates.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _DateChip(
                            date: placeDates[i],
                            selected: _date == i,
                            onTap: () => setState(() => _date = i),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const _Label('시간'),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 7,
                    crossAxisSpacing: 7,
                    childAspectRatio: 2.15,
                    children: [
                      for (final time in placeTimes)
                        _TimeChip(
                          time: time,
                          selected: _time == time.label,
                          onTap: time.open
                              ? () => setState(() => _time = time.label)
                              : null,
                        ),
                    ],
                  ),
                  const _Label('인원'),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.chip),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Step(
                          icon: Icons.remove,
                          onTap: _headcount > 1
                              ? () => setState(() => _headcount -= 1)
                              : null,
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$_headcount',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const TextSpan(
                                text: ' 명',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Step(
                          icon: Icons.add,
                          onTap: _headcount < place.capacity
                              ? () => setState(() => _headcount += 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const _Label('연결할 모임'),
                  Material(
                    color: placeField,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                      side: const BorderSide(color: AppColors.line),
                    ),
                    child: InkWell(
                      onTap: _pickMeeting,
                      borderRadius: BorderRadius.circular(11),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _meeting,
                                style: const TextStyle(
                                  fontSize: 13,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.expand_more,
                              size: 18,
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const _Label('요청사항'),
                  TextField(
                    controller: _note,
                    style: const TextStyle(fontSize: 13, letterSpacing: -0.4),
                    decoration: InputDecoration(
                      hintText: '예: 단체석으로 붙여 주세요',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: placeHint,
                      ),
                      filled: true,
                      fillColor: placeField,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PlacePanel(
                    child: Column(
                      children: [
                        PlaceMoneyLine(
                          '예약금 (1인 ${formatWon(placeDepositPerPerson)} × $_headcount명)',
                          formatWon(_deposit),
                        ),
                        const Divider(height: 24, color: AppColors.chip),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '예약금은 당일 결제 금액에서 빠져요',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.8,
                              letterSpacing: -0.4,
                              color: AppColors.rowLabel,
                            ),
                          ),
                        ),
                      ],
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
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final PlaceDate date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.chip),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(
                date.weekday,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: selected ? const Color(0xFFC9DBCA) : AppColors.muted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date.day,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final PlaceTime time;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final closed = !time.open;
    return Material(
      color: closed ? placeTimeOff : (selected ? placeTimeOn : AppColors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.chip),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Center(
          child: Text(
            time.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              decoration: closed ? TextDecoration.lineThrough : null,
              color: closed
                  ? placeTimeOffInk
                  : (selected ? AppColors.primary : AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: placeCounter,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.primary : AppColors.bud,
          ),
        ),
      ),
    );
  }
}
