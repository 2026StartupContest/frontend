import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key, required this.deps, required this.created});

  final MoaDependencies deps;
  final CreatedClub created;

  @override
  Widget build(BuildContext context) {
    final code = created.invite.code;
    final expires = formatShortDay(created.invite.expiresAt);
    final name = deps.auth.currentDisplayName ?? '회원';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const MoaPageHeader(title: '구성원 초대하기'),
            const SizedBox(height: 12),
            const Center(
              child: CircleAvatar(
                radius: 37,
                backgroundColor: AppColors.caper,
                child: Icon(Icons.check, color: AppColors.primary, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${created.club.name}가\n만들어졌어요!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '$name님은 이 동아리의 회장이에요.\n구성원들을 초대해 볼까요?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.caper, borderRadius: BorderRadius.circular(99)),
                    child: const Text('동아리 초대 코드', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  QrImageView(data: code, size: 150, eyeStyle: const QrEyeStyle(color: AppColors.ink)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final char in code.split(''))
                        Container(
                          width: 40,
                          height: 48,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(char, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('코드와 QR은 $expires까지 쓸 수 있어요', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MoaOutlineButton(
                    label: '코드 복사',
                    icon: Icons.copy,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('코드를 복사했어요.')));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MoaOutlineButton(
                    label: '링크 공유',
                    icon: Icons.ios_share,
                    onPressed: () => SharePlus.instance.share(ShareParams(text: '${created.club.name} 초대 코드 $code')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MoaPrimaryButton(
              label: '동아리 홈으로 가기',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (_) => false,
                arguments: HomeArgs(created.club.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
