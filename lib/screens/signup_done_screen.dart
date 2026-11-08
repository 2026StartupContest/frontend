import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

class SignupDoneScreen extends StatelessWidget {
  const SignupDoneScreen({super.key, required this.deps, required this.args});

  final MoaDependencies deps;
  final SignupDoneArgs args;

  @override
  Widget build(BuildContext context) {
    final name = args.name.isEmpty ? '회원' : args.name;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                children: [
                  const MoaStepper(active: 2),
                  const SizedBox(height: 48),
                  Center(
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: const BoxDecoration(color: AppColors.caper, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: AppColors.primary, size: 34),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '가입을 환영해요,\n$name님!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, height: 1.3, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '이제 동아리를 새로 만들거나\n초대받은 동아리에 가입해 보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.45),
                  ),
                  const SizedBox(height: 28),
                  _row('이름', args.name),
                  const SizedBox(height: 8),
                  _row('이메일', args.email),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: MoaPrimaryButton(
                label: '시작하기',
                onPressed: () => openLaunch(context, deps),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
