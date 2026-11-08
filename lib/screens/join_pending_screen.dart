import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

class JoinPendingScreen extends StatefulWidget {
  const JoinPendingScreen({super.key, required this.deps, required this.clubId});

  final MoaDependencies deps;
  final String clubId;

  @override
  State<JoinPendingScreen> createState() => _JoinPendingScreenState();
}

class _JoinPendingScreenState extends State<JoinPendingScreen> {
  PendingView? _view;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final view = await widget.deps.clubs.loadPending(uid: uid, clubId: widget.clubId);
      if (mounted) setState(() => _view = view);
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const MoaPageHeader(title: '가입 신청 현황'),
            const Center(
              child: CircleAvatar(
                radius: 37,
                backgroundColor: AppColors.caper,
                child: Icon(Icons.hourglass_top, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            const Text('입금을 확인하고 있어요', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              view == null ? '신청 내용을 불러오고 있어요.' : '${view.club.name} 회장이 입금을 확인하면 알려드릴게요.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            if (view != null) _steps(view),
            const SizedBox(height: 16),
            if (view != null)
              MoaOutlineButton(
                label: '회장에게 확인 요청',
                onPressed: () async {
                  final uid = widget.deps.auth.currentUid;
                  if (uid == null) return;
                  await widget.deps.clubs.askOwner(
                    uid: uid,
                    userName: view.membership.userName,
                    clubId: view.club.id,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회장에게 확인을 요청했어요.')));
                },
              ),
            TextButton(
              onPressed: () async {
                final uid = widget.deps.auth.currentUid;
                if (uid == null) return;
                await widget.deps.clubs.cancelJoin(uid: uid, clubId: widget.clubId);
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.noClub, (_) => false);
              },
              child: const Text('가입 신청 취소', style: TextStyle(color: AppColors.label)),
            ),
            if (_message != null) Text(_message!, style: const TextStyle(color: AppColors.danger)),
          ],
        ),
      ),
    );
  }

  Widget _steps(PendingView view) {
    final requested = view.membership.requestedAt;
    final steps = [
      ('가입 신청 완료', requested == null ? '' : formatMonthDay(requested), true),
      (
        '가입비 입금 신고',
        view.membership.feeReported
            ? '${view.club.feeAmount == null ? '' : formatWon(view.club.feeAmount!)} · 입금자명 ${view.membership.depositName ?? ''}'
            : '입금 전',
        view.membership.feeReported,
      ),
      ('회장 입금 확인 중', '보통 1~2일 안에 확인돼요', false),
      ('가입 완료', '동아리 홈과 공지를 바로 볼 수 있어요', false),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: steps[i].$3 ? AppColors.primary : AppColors.chip,
                      child: Text('${i + 1}', style: TextStyle(color: steps[i].$3 ? AppColors.white : AppColors.ink, fontSize: 12)),
                    ),
                    if (i != steps.length - 1) Container(width: 2, height: 28, color: AppColors.line),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (steps[i].$2.isNotEmpty) Text(steps[i].$2, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
