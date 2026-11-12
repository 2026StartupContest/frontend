import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/place_widgets.dart';

class PlaceConfirmScreen extends StatelessWidget {
  const PlaceConfirmScreen({super.key, required this.args});

  final PlaceFlowArgs args;

  @override
  Widget build(BuildContext context) {
    final draft = args.draft!;
    final place = placeById(draft.placeId);
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: PlaceBottomBar(
        top: PlaceMoneyLine(
          '결제할 예약금',
          formatWon(draft.deposit),
          valueColor: AppColors.primary,
          strong: true,
        ),
        child: AttendanceButton(
          label: '페이로 결제하기',
          height: 50,
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.placeReserved,
              arguments: PlaceFlowArgs(
                clubId: args.clubId,
                placeId: place.id,
                draft: draft,
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AttendanceAppBar(title: '예약 확인'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                children: [
                  const Row(
                    children: [
                      Text(
                        '01 예약 확인',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 24,
                        child: Divider(color: AppColors.line, thickness: 1),
                      ),
                      SizedBox(width: 10),
                      Text(
                        '02 결제',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '예약 내용을 확인해 주세요',
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '결제 전, 날짜와 인원을 한 번 더 확인해요.',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: -0.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  PlacePanel(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const PlaceMark(size: 50),
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                      if (place.partner) ...[
                                        const SizedBox(width: 6),
                                        const PlacePartnerBadge(),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 5),
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
                        const Divider(height: 32, color: AppColors.chip),
                        PlaceMoneyLine('일시', draft.whenLabel),
                        const SizedBox(height: 13),
                        PlaceMoneyLine('인원', '${draft.headcount}명'),
                        const SizedBox(height: 13),
                        PlaceMoneyLine('모임', draft.meetingName),
                        const SizedBox(height: 13),
                        PlaceMoneyLine(
                          '요청사항',
                          draft.noteLabel,
                          valueColor: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PlacePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlaceMoneyLine(
                          '예약금',
                          formatWon(draft.deposit),
                          valueColor: AppColors.primary,
                          big: true,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '1인 ${formatWon(placeDepositPerPerson)} × ${draft.headcount}명',
                          style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: -0.4,
                            color: AppColors.rowLabel,
                          ),
                        ),
                        const Divider(height: 24, color: AppColors.chip),
                        const Text(
                          '예약금은 당일 결제 금액에서 빠져요',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.8,
                            letterSpacing: -0.4,
                            color: AppColors.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const PlaceNote(
                    tone: PlaceNoteTone.green,
                    text: '결제 후 사장님 확인을 거쳐 예약 확정\n사장님이 확인하면 예약이 확정되고 참석자들에게 알림이 가요.\n예약이 확정되면 결제 금액이 N차 정산 1차에 자동으로 들어가요.',
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
