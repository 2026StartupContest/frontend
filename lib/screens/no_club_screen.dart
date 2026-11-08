import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

class NoClubScreen extends StatelessWidget {
  const NoClubScreen({super.key, required this.deps});

  final MoaDependencies deps;

  @override
  Widget build(BuildContext context) {
    final name = deps.auth.currentDisplayName ?? '회원';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            Row(
              children: [
                const Text('모아', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    await deps.auth.signOut();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(color: AppColors.caper, shape: BoxShape.circle),
                child: const Icon(Icons.emergency, size: 64, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 28),
            Text('WELCOME, $name님', textAlign: TextAlign.center, style: const TextStyle(letterSpacing: 0.6, color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('아직 함께하는 동아리가 없어요', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              '새 동아리를 만들거나,\n초대받은 코드로 바로 가입해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 28),
            MoaPrimaryButton(
              label: '새 동아리 만들기',
              icon: Icons.add,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.createClub),
            ),
            const SizedBox(height: 12),
            MoaPrimaryButton(
              label: '초대 코드로 가입하기',
              icon: Icons.vpn_key_outlined,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.join),
            ),
            const SizedBox(height: 16),
            const Text(
              'QR 코드를 받았다면 카메라로 바로 스캔해도 돼요',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
