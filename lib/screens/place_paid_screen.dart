import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/place_widgets.dart';

class PlacePaidScreen extends StatelessWidget {
  const PlacePaidScreen({super.key, required this.args});

  final PlaceFlowArgs args;

  @override
  Widget build(BuildContext context) {
    final items = reservationsByIds(args.reservationIds);
    final total = reservationTotalSum(items);
    final deposit = reservationDepositSum(items);
    final balance = reservationBalanceSum(items);
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: PlaceBottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AttendanceButton(
              label: '결제 내역 보기',
              height: 50,
              onPressed: () =>
                  placeDummyNotice(context, '예시 화면이라 별도 영수증은 없어요.'),
            ),
            const SizedBox(height: 10),
            AttendanceButton(
              label: '예약 목록으로',
              tone: AttendanceButtonTone.soft,
              height: 50,
              onPressed: () => _backToList(context),
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AttendanceAppBar(
              title: '결제 완료',
              trailing: AttendanceIconButton(
                icon: 'close',
                label: '닫기',
                onPressed: () => _backToList(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  const Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.all(Radius.circular(26)),
                      ),
                      child: SizedBox(
                        width: 74,
                        height: 74,
                        child: Icon(
                          Icons.check,
                          color: AppColors.caper,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${items.length}건의 결제를 마쳤어요',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '함께한 모임의 이용금액을 모두 결제했어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.8,
                      letterSpacing: -0.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  PlacePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlaceMoneyLine(
                          '총 결제금액',
                          formatWon(balance),
                          valueColor: AppColors.primary,
                          big: true,
                        ),
                        const Divider(height: 24, color: AppColors.chip),
                        const PlaceMoneyLine('결제 수단', placeCardPaid),
                        const SizedBox(height: 12),
                        const PlaceMoneyLine('결제 일시', placePaidAt),
                        const SizedBox(height: 12),
                        Text(
                          '총 이용금액 ${formatWon(total)} − 예약금 ${formatWon(deposit)}',
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: -0.4,
                            color: AppColors.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PlacePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '결제된 예약',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 24, color: AppColors.chip),
                          const SizedBox(height: 12),
                          _PaidItem(item: items[i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const PlaceNote(
                    text: '선결제한 예약금을 제외한 잔액 결제 내역이에요.\n영수증은 결제 내역에서 확인할 수 있어요.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _backToList(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.reservations,
      (route) => route.settings.name == AppRoutes.places || route.isFirst,
      arguments: PlaceFlowArgs(clubId: args.clubId, usedTab: true),
    );
  }
}

class _PaidItem extends StatelessWidget {
  const _PaidItem({required this.item});

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
            const PlaceStatusBadge(
              '결제 완료',
              background: placeGreenNote,
              foreground: AppColors.primary,
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
        const SizedBox(height: 6),
        PlaceMoneyLine(item.meeting, formatWon(item.balance)),
      ],
    );
  }
}
