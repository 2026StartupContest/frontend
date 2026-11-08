import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/moa_bottom_nav.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.deps, required this.clubId});

  final MoaDependencies deps;
  final String clubId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeData? _data;
  String? _message;
  late String _clubId;

  @override
  void initState() {
    super.initState();
    _clubId = widget.clubId;
    _load();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final data = await widget.deps.clubs.loadHome(uid: uid, clubId: _clubId);
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    }
  }

  Future<void> _openNotices() async {
    final data = _data;
    if (data == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
                Row(
                  children: [
                    const Expanded(child: Text('새로운 소식', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const Text('놓치지 않도록 모아뒀어요. 읽지 않은 알림은 초록 점으로 표시돼요.', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                if (data.notices.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('새로운 소식이 없어요.'))
                else
                  for (final notice in data.notices) _notice(notice),
              ],
            );
          },
        );
      },
    );
    await widget.deps.clubs.markNoticesRead(data.club.id);
    await _load();
  }

  Future<void> _account() async {
    final data = _data;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data?.user.name ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(data?.user.email ?? '', style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              MoaPrimaryButton(
                label: '로그아웃',
                onPressed: () async {
                  await widget.deps.auth.signOut();
                  if (!mounted || !context.mounted) return;
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(this.context, AppRoutes.login, (_) => false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      extendBody: true,
      body: data == null
          ? Center(child: _message == null ? const CircularProgressIndicator(color: AppColors.primary) : Text(_message!))
          : SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  _top(data),
                  const SizedBox(height: 18),
                  const Text('OUR CLUB, ALL TOGETHER', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  const SizedBox(height: 8),
                  Text('안녕하세요, ${data.user.name}님.\n오늘도 함께 모아봐요!', style: const TextStyle(fontSize: 26, height: 1.3, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  _balance(data.club),
                  const SizedBox(height: 22),
                  _section('오늘의 모임'),
                  if (data.events.isEmpty)
                    const _EmptyLine('오늘 예정된 모임이 없어요')
                  else
                    for (final event in data.events) _event(event),
                  const SizedBox(height: 18),
                  _quick(),
                  const SizedBox(height: 22),
                  _section('지금 확인해 주세요'),
                  if (data.tasks.isEmpty)
                    const _EmptyLine('확인할 일이 없어요')
                  else
                    for (final task in data.tasks) _task(task),
                  const SizedBox(height: 22),
                  _section('차곡차곡, 최근 기록'),
                  if (data.activities.isEmpty)
                    const _EmptyLine('아직 기록이 없어요')
                  else
                    for (final item in data.activities) _activity(item),
                ],
              ),
            ),
      bottomNavigationBar: MoaBottomNav(
        selected: MoaTab.home,
        onSelected: (tab) {
          if (tab != MoaTab.home) return;
        },
      ),
    );
  }

  Widget _top(HomeData data) {
    return Row(
      children: [
        InkWell(
          onTap: data.clubs.length < 2
              ? null
              : () async {
                  final picked = await showModalBottomSheet<String>(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final club in data.clubs)
                            ListTile(
                              title: Text(club.name),
                              subtitle: Text(club.tagline),
                              onTap: () => Navigator.pop(context, club.id),
                            ),
                        ],
                      ),
                    ),
                  );
                  if (picked != null && picked != _clubId) {
                    setState(() => _clubId = picked);
                    await _load();
                  }
                },
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.primary, child: Text(data.club.name.isEmpty ? '모' : data.club.name.characters.first, style: const TextStyle(color: AppColors.white))),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.club.tagline, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  Row(
                    children: [
                      Text(data.club.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _openNotices,
          icon: Badge(isLabelVisible: data.hasUnread, smallSize: 8, child: const Icon(Icons.notifications_none)),
        ),
        IconButton(onPressed: _account, icon: const Icon(Icons.settings_outlined)),
      ],
    );
  }

  Widget _balance(Club club) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('우리 동아리 공용 잔액', style: TextStyle(color: AppColors.caper)),
              const Spacer(),
              if (club.duesMonthLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
                  child: Text(club.duesMonthLabel, style: const TextStyle(color: AppColors.white, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              text: formatGrouped(club.balance),
              style: const TextStyle(color: AppColors.white, fontSize: 34, fontWeight: FontWeight.w800),
              children: const [TextSpan(text: '원', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            club.duesTotalCount == 0 ? '이번 달 회비 내역이 없어요' : '이번 달 회비 납부  ${club.duesPaidCount} / ${club.duesTotalCount}명',
            style: const TextStyle(color: AppColors.caper),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    );
  }

  Widget _event(ClubEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 96,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.artKicker, style: const TextStyle(color: AppColors.caper, fontSize: 12)),
                Text(event.artTitle, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.badge, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(event.schedule, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                if (event.attendeeSummary.isNotEmpty) Text(event.attendeeSummary, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quick() {
    const items = [
      (Icons.account_balance_wallet_outlined, '회비 관리'),
      (Icons.qr_code_2, 'QR 출석'),
      (Icons.calculate_outlined, 'N차 정산'),
      (Icons.menu_book_outlined, '회계 장부'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final item in items)
          Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                child: Icon(item.$1, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(item.$2, style: const TextStyle(fontSize: 12)),
            ],
          ),
      ],
    );
  }

  Widget _task(HomeTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: AppColors.caper, child: Icon(Icons.person_outline, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${task.title}${task.count == null ? '' : ' ${task.count}'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(task.subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.bud),
        ],
      ),
    );
  }

  Widget _activity(ActivityItem item) {
    final color = item.income ? AppColors.primary : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.chip, child: Icon(item.income ? Icons.south_west : Icons.north_east, size: 16, color: color)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(item.subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.income ? '+' : ''}${formatWon(item.amount)}', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
              Text(item.amountNote, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notice(ClubNotice notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: AppColors.caper, child: Icon(Icons.notifications_none, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notice.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(notice.body, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          if (notice.unread) const Text('새 알림', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: AppColors.muted)),
    );
  }
}
