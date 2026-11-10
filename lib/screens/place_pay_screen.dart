import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/place_widgets.dart';

class PlacePayScreen extends StatefulWidget {
  const PlacePayScreen({super.key, required this.args});

  final PlaceFlowArgs args;

  @override
  State<PlacePayScreen> createState() => _PlacePayScreenState();
}

class _PlacePayScreenState extends State<PlacePayScreen> {
  late List<bool> _agreed = List.filled(placeTerms.length, true);

  List<DummyReservation> get _items =>
      reservationsByIds(widget.args.reservationIds);

  bool get _ready => _agreed.every((item) => item);

  void _toggleAll(bool value) =>
      setState(() => _agreed = List.filled(placeTerms.length, value));

  void _toggle(int index) {
    setState(() => _agreed[index] = !_agreed[index]);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final total = reservationTotalSum(items);
    final deposit = reservationDepositSum(items);
    final balance = reservationBalanceSum(items);
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: PlaceBottomBar(
        top: PlaceMoneyLine(
          '총 ${items.length}건 · 최종 결제금액',
          formatWon(balance),
          valueColor: AppColors.primary,
        ),
        child: AttendanceButton(
          label: '${formatWon(balance)} 결제하기',
          height: 50,
          onPressed: _ready
              ? () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.reservationPaid,
                    arguments: PlaceFlowArgs(
                      clubId: widget.args.clubId,
                      reservationIds: widget.args.reservationIds,
                    ),
                  );
                }
              : null,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AttendanceAppBar(title: '이용 후 일괄 결제'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                children: [
                  PlaceHeadline(
                    title: '남은 금액만 결제해 주세요',
                    subtitle: '이용을 마친 예약 ${items.length}건을 함께 결제해요.',
                  ),
                  const SizedBox(height: 18),
                  PlacePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '결제할 예약 ${items.length}건',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 28, color: AppColors.chip),
                          if (i == 0) const SizedBox(height: 12),
                          _PayItem(item: items[i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PlacePanel(
                    child: Column(
                      children: [
                        PlaceMoneyLine('총 이용금액', formatWon(total)),
                        const SizedBox(height: 12),
                        PlaceMoneyLine(
                          '예약금 차감 합계',
                          placeMinusWon(deposit),
                          valueColor: AppColors.primary,
                        ),
                        const Divider(height: 24, color: AppColors.chip),
                        PlaceMoneyLine(
                          '최종 결제금액',
                          formatWon(balance),
                          valueColor: AppColors.primary,
                          big: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '결제 수단',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: placeTimeOn,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.credit_card,
                            size: 22,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  placeCardName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.4,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  placeCardDetail,
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: -0.4,
                                    color: AppColors.label,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                placeDummyNotice(context, '예시 카드라서 바꿀 수 없어요.'),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '변경',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: () => _toggleAll(!_ready),
                    child: Row(
                      children: [
                        PlaceCheck(checked: _ready),
                        const SizedBox(width: 9),
                        const Text(
                          '필수 항목 전체 동의',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20, color: AppColors.chip),
                  for (var i = 0; i < placeTerms.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => _toggle(i),
                            child: PlaceCheck(checked: _agreed[i], size: 18),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              placeTerms[i],
                              style: const TextStyle(
                                fontSize: 12,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => placeDummyNotice(context, '예시 약관이에요.'),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                '›',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  PlaceNote(
                    text:
                        '예약금 ${formatWon(deposit)}원은 다시 청구하지 않아요.\n확인한 이용 내역의 잔액만 결제돼요.',
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

class _PayItem extends StatelessWidget {
  const _PayItem({required this.item});

  final DummyReservation item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.placeName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            Text(
              formatWon(item.balance),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          item.party,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: -0.4,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 9),
        PlaceMoneyLine('이용금액', formatWon(item.total)),
        const SizedBox(height: 9),
        PlaceMoneyLine(
          '선결제 예약금 차감',
          placeMinusWon(item.deposit),
          valueColor: AppColors.primary,
        ),
      ],
    );
  }
}
