import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/place_widgets.dart';

class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key, required this.args});

  final PlaceFlowArgs args;

  @override
  Widget build(BuildContext context) {
    final item = reservationById(args.reservationId!);
    if (item.kind == ReservationKind.upcoming) {
      return _UpcomingDetail(item: item);
    }
    return _UsedDetail(args: args, item: item);
  }
}

class _UpcomingDetail extends StatelessWidget {
  const _UpcomingDetail({required this.item});

  final DummyReservation item;

  @override
  Widget build(BuildContext context) {
    final pending = item.badge == ReservationBadge.pending;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AttendanceAppBar(title: '예약 상세'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                children: [
                  PlacePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlaceStatusBadge(
                          reservationBadgeLabel(item.badge),
                          background: pending
                              ? AppColors.peach
                              : placeGreenNote,
                          foreground: pending
                              ? AppColors.copper
                              : AppColors.primary,
                        ),
                        const SizedBox(height: 12),
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
                        const Divider(height: 24, color: AppColors.chip),
                        PlaceMoneyLine(
                          '선결제 예약금',
                          '${formatWon(item.deposit)} 납부 완료',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const PlaceNote(text: '미리 낸 예약금은 이용 후 결제 금액에서 빠져요.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsedDetail extends StatelessWidget {
  const _UsedDetail({required this.args, required this.item});

  final PlaceFlowArgs args;
  final DummyReservation item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: PlaceBottomBar(
        top: PlaceMoneyLine(
          '이 예약의 남은 금액',
          formatWon(item.balance),
          valueColor: AppColors.primary,
        ),
        child: AttendanceButton(
          label: '예약 목록에서 함께 결제하기',
          height: 50,
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.reservations,
              arguments: PlaceFlowArgs(clubId: args.clubId, usedTab: true),
            );
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AttendanceAppBar(title: '이용 내역 상세'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                children: [
                  PlacePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            PlaceStatusBadge(
                              '이용 완료',
                              background: placeGreenNote,
                              foreground: AppColors.primary,
                            ),
                            SizedBox(width: 6),
                            PlaceStatusBadge(
                              '미결제',
                              background: AppColors.peach,
                              foreground: AppColors.copper,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                    ),
                  ),
                  const SizedBox(height: 18),
                  PlacePanel(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              '이용한 메뉴',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${item.lines.length}개 항목',
                              style: const TextStyle(
                                fontSize: 11,
                                letterSpacing: -0.4,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final line in item.lines) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${formatWon(line.unitPrice)} × ${line.quantity}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        letterSpacing: -0.4,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatWon(line.amount),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 24, color: AppColors.chip),
                        PlaceMoneyLine('총 이용금액', formatWon(item.total)),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '부가세가 포함된 금액이에요.',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: -0.4,
                              color: AppColors.muted,
                            ),
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
                          '남은 결제금액',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        PlaceMoneyLine('총 이용금액', formatWon(item.total)),
                        const SizedBox(height: 12),
                        PlaceMoneyLine(
                          '이미 낸 예약금',
                          placeMinusWon(item.deposit),
                          valueColor: AppColors.primary,
                        ),
                        const Divider(height: 24, color: AppColors.chip),
                        PlaceMoneyLine(
                          '이번에 결제할 금액',
                          formatWon(item.balance),
                          valueColor: AppColors.primary,
                          big: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PlaceNote(
                    text:
                        '예약금 ${formatWon(item.deposit)}원은 이미 납부했어요.\n예약 목록에서 다른 미결제 예약과 함께 결제해요.',
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
