import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/place_widgets.dart';

class PlaceReservedScreen extends StatelessWidget {
  const PlaceReservedScreen({super.key, required this.args});

  final PlaceFlowArgs args;

  @override
  Widget build(BuildContext context) {
    final draft = args.draft!;
    final place = placeById(draft.placeId);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AttendanceAppBar(close: true, onBack: () => _close(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                children: [
                  const SizedBox(height: 20),
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
                          Icons.near_me_outlined,
                          color: AppColors.caper,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '예약 요청을 보냈어요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${place.name} 사장님이 확인하면 예약이 확정되고\n참석자들에게 알림이 가요.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.8,
                      letterSpacing: -0.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  PlacePanel(
                    child: Column(
                      children: [
                        PlaceMoneyLine('장소', place.name),
                        const Divider(height: 24, color: AppColors.chip),
                        PlaceMoneyLine('일시', draft.whenLabel),
                        const Divider(height: 24, color: AppColors.chip),
                        PlaceMoneyLine('인원', '${draft.headcount}명'),
                        const Divider(height: 24, color: AppColors.chip),
                        PlaceMoneyLine('모임', draft.meetingName),
                        const Divider(height: 24, color: AppColors.chip),
                        const Row(
                          children: [
                            Text(
                              '상태',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: -0.4,
                                color: AppColors.rowLabel,
                              ),
                            ),
                            Spacer(),
                            PlaceStatusBadge(
                              '사장님 확인 중',
                              background: AppColors.peach,
                              foreground: AppColors.copper,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  const PlaceNote(text: '예약이 확정되면 결제 금액이 N차 정산 1차에 자동으로 들어가요.'),
                  const SizedBox(height: 16),
                  AttendanceButton(
                    label: '모임 공지로 공유하기',
                    onPressed: () =>
                        placeDummyNotice(context, '예시 화면이라 공지는 보내지 않아요.'),
                  ),
                  const SizedBox(height: 10),
                  AttendanceButton(
                    label: '예약 목록 보기',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.reservations,
                        arguments: PlaceFlowArgs(clubId: args.clubId),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  AttendanceButton(
                    label: '모임 목록으로',
                    tone: AttendanceButtonTone.soft,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.meetings,
                        arguments: ClubArgs(args.clubId),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _close(BuildContext context) {
    var found = false;
    Navigator.popUntil(context, (route) {
      final back = route.settings.name == AppRoutes.places;
      if (back) found = true;
      return back || route.isFirst;
    });
    if (!found && context.mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.places,
        arguments: PlaceFlowArgs(clubId: args.clubId),
      );
    }
  }
}
