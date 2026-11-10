import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/place_widgets.dart';

class PlaceListScreen extends StatefulWidget {
  const PlaceListScreen({super.key, required this.args});

  final PlaceFlowArgs args;

  @override
  State<PlaceListScreen> createState() => _PlaceListScreenState();
}

class _PlaceListScreenState extends State<PlaceListScreen> {
  late bool _used = widget.args.usedTab;
  late Set<String> _picked = {for (final item in usedReservations) item.id};

  List<DummyReservation> get _selected =>
      usedReservations.where((item) => _picked.contains(item.id)).toList();

  void _open(DummyReservation item) {
    Navigator.pushNamed(
      context,
      AppRoutes.reservationDetail,
      arguments: PlaceFlowArgs(
        clubId: widget.args.clubId,
        reservationId: item.id,
      ),
    );
  }

  void _pay() {
    final ids = _selected.map((item) => item.id).toList();
    if (ids.isEmpty) return;
    Navigator.pushNamed(
      context,
      AppRoutes.reservationPay,
      arguments: PlaceFlowArgs(clubId: widget.args.clubId, reservationIds: ids),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = upcomingReservations;
    final used = usedReservations;
    final selected = _selected;
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _used
          ? PlaceBottomBar(
              top: PlaceMoneyLine(
                '선택한 ${selected.length}건의 결제금액',
                formatWon(reservationBalanceSum(selected)),
                valueColor: AppColors.primary,
              ),
              child: AttendanceButton(
                label: selected.isEmpty
                    ? '결제할 예약을 골라 주세요'
                    : '${selected.length}건 한 번에 결제하기',
                height: 50,
                onPressed: selected.isEmpty ? null : _pay,
              ),
            )
          : PlaceBottomBar(
              child: AttendanceButton(
                label: '새로운 모임 장소 찾기',
                tone: AttendanceButtonTone.soft,
                height: 50,
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.places,
                    arguments: PlaceFlowArgs(clubId: widget.args.clubId),
                  );
                },
              ),
            ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AttendanceAppBar(title: '예약 목록'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                children: [
                  PlaceHeadline(
                    title: _used ? '이용한 예약을 한 번에 결제해요' : '우리 모임의 예약',
                    subtitle: _used
                        ? '예약금을 뺀 남은 금액만 결제할 수 있어요.'
                        : '예약부터 이용 후 결제까지 한곳에서 확인해요.',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _Tab(
                        label: '다가오는 예약 ${upcoming.length}',
                        selected: !_used,
                        onTap: () => setState(() => _used = false),
                      ),
                      const SizedBox(width: 20),
                      _Tab(
                        label: '이용 완료 ${used.length}',
                        selected: _used,
                        onTap: () => setState(() => _used = true),
                      ),
                    ],
                  ),
                  const Divider(height: 1, color: AppColors.chip),
                  const SizedBox(height: 18),
                  if (_used) ...[
                    _SelectAll(
                      count: _picked.length,
                      total: used.length,
                      onTap: () => setState(() {
                        if (_picked.length == used.length) {
                          _picked = {};
                        } else {
                          _picked = {for (final item in used) item.id};
                        }
                      }),
                    ),
                    const SizedBox(height: 18),
                    for (final item in used) ...[
                      _UsedCard(
                        item: item,
                        picked: _picked.contains(item.id),
                        onToggle: () => setState(() {
                          if (!_picked.add(item.id)) _picked.remove(item.id);
                        }),
                        onOpen: () => _open(item),
                      ),
                      const SizedBox(height: 18),
                    ],
                    PlaceNote(
                      text:
                          '이미 납부한 예약금 ${formatWon(reservationDepositSum(used))}원은 제외했어요.\n선택한 예약의 잔액만 한 번에 결제해요.',
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Text(
                          '다가오는 예약 ${upcoming.length}건',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '가까운 날짜순',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: -0.4,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    for (final item in upcoming) ...[
                      _UpcomingCard(item: item, onOpen: () => _open(item)),
                      const SizedBox(height: 18),
                    ],
                    const PlaceNote(
                      text: '미리 낸 예약금은 이용 후 결제 금액에서 빠져요.\n이용을 마친 예약은 ‘이용 완료’에서 확인해요.',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: selected ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _SelectAll extends StatelessWidget {
  const _SelectAll({
    required this.count,
    required this.total,
    required this.onTap,
  });

  final int count;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          PlaceCheck(checked: count == total && total > 0),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '전체 선택 ($count/$total)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
              ),
            ),
          ),
          PlaceStatusBadge(
            '미결제 $total건',
            background: AppColors.peach,
            foreground: AppColors.copper,
          ),
        ],
      ),
    );
  }
}

class _PlaceSummary extends StatelessWidget {
  const _PlaceSummary({required this.item});

  final DummyReservation item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const PlaceMark(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.placeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.meeting,
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: -0.4,
                      color: AppColors.rowLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          item.party,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _DetailLink extends StatelessWidget {
  const _DetailLink(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.item, required this.onOpen});

  final DummyReservation item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final pending = item.badge == ReservationBadge.pending;
    return PlacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlaceStatusBadge(
                reservationBadgeLabel(item.badge),
                background: pending ? AppColors.peach : placeGreenNote,
                foreground: pending ? AppColors.copper : AppColors.primary,
              ),
              const Spacer(),
              if (item.countdown != null)
                Text(
                  item.countdown!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _PlaceSummary(item: item),
          const Divider(height: 24, color: AppColors.chip),
          PlaceMoneyLine('선결제 예약금', '${formatWon(item.deposit)} 납부 완료'),
          const SizedBox(height: 8),
          _DetailLink('예약 상세 보기', onTap: onOpen),
        ],
      ),
    );
  }
}

class _UsedCard extends StatelessWidget {
  const _UsedCard({
    required this.item,
    required this.picked,
    required this.onToggle,
    required this.onOpen,
  });

  final DummyReservation item;
  final bool picked;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return PlacePanel(
      borderColor: picked ? AppColors.primary : AppColors.chip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                PlaceCheck(checked: picked),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    '이용 완료',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const PlaceStatusBadge(
                  '미결제',
                  background: AppColors.peach,
                  foreground: AppColors.copper,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PlaceSummary(item: item),
          const Divider(height: 24, color: AppColors.chip),
          PlaceMoneyLine('총 이용금액', formatWon(item.total)),
          const SizedBox(height: 9),
          PlaceMoneyLine(
            '선결제 예약금 차감',
            placeMinusWon(item.deposit),
            valueColor: AppColors.primary,
          ),
          const SizedBox(height: 9),
          PlaceMoneyLine(
            '남은 결제금액',
            formatWon(item.balance),
            valueColor: AppColors.primary,
            big: true,
          ),
          const SizedBox(height: 8),
          _DetailLink('이용 내역 상세', onTap: onOpen),
        ],
      ),
    );
  }
}
