import 'package:flutter/material.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/meeting_filter.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/core/accounting.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/club_sheets.dart';
import 'package:flutter_proj/widgets/moa_bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';

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
      if (mounted) {
        setState(() {
          _data = data;
          _message = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = friendlyErrorMessage(error));
      }
    }
  }

  void _retry() {
    setState(() => _message = null);
    _load();
  }

  Future<void> _openNotices() async {
    final data = _data;
    if (data == null) return;
    await showNoticeSheet(context, data.notices);
    await widget.deps.clubs.markNoticesRead(data.club.id);
    await _load();
  }

  Future<void> _openClubs() async {
    final data = _data;
    if (data == null) return;
    await showClubSwitcher(
      context: context,
      options: data.options,
      onPrimary: (option) async {
        final uid = widget.deps.auth.currentUid;
        if (uid == null) return;
        try {
          await widget.deps.clubs.setPrimaryClub(
            uid: uid,
            clubId: option.club.id,
          );
          await _load();
        } catch (error) {
          if (mounted) await showMoaError(context, error);
          rethrow;
        }
      },
      onOpen: (option) {
        if (option.isPending) {
          Navigator.pushNamed(
            context,
            AppRoutes.joinPending,
            arguments: ClubArgs(option.club.id),
          );
          return;
        }
        if (option.club.id == _clubId) return;
        setState(() {
          _clubId = option.club.id;
          _data = null;
        });
        _load();
      },
      onCreate: () => Navigator.pushNamed(context, AppRoutes.createClub),
      onJoin: () => Navigator.pushNamed(context, AppRoutes.join),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.clubSettings,
      arguments: ClubArgs(_clubId),
    );
    await _load();
  }

  Future<void> _openMeetings() {
    return Navigator.pushNamed(
      context,
      AppRoutes.meetings,
      arguments: ClubArgs(_clubId),
    );
  }

  Future<void> _openInbox() {
    return Navigator.pushNamed(
      context,
      AppRoutes.joinInbox,
      arguments: ClubArgs(_clubId),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: data == null
          ? _message == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : MoaErrorState(message: _message!, onRetry: _retry)
          : SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  ClubTopBar(
                    club: data.club,
                    hasUnread: data.hasUnread,
                    showSettings: ClubAccess.showsSettings(data.role),
                    onClub: _openClubs,
                    onNotices: _openNotices,
                    onSettings: _openSettings,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OUR CLUB, ALL TOGETHER',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 24,
                                    height: 1.5,
                                    letterSpacing: -1.2,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '안녕하세요, ${data.user.name}님.\n',
                                    ),
                                    const TextSpan(text: '오늘도 '),
                                    TextSpan(
                                      text: '함께 모아봐요!',
                                      style: GoogleFonts.notoSansKr(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 24,
                                        letterSpacing: -1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Transform.rotate(
                              angle: 12 * 3.14159 / 180,
                              child: const HomeIcon('asterisk'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        SectionTitle(
                          title: '오늘의 모임',
                          action: '전체보기',
                          onAction: _openMeetings,
                        ),
                        const SizedBox(height: 12),
                        ..._events(data),
                        const SizedBox(height: 22),
                        QuickActions(
                          onAction: (key) {
                            if (key == 'dues') {
                              openAccounting(
                                context,
                                _clubId,
                                segment: AccountingSegment.dues,
                              );
                            }
                            if (key == 'ledger') {
                              openAccounting(
                                context,
                                _clubId,
                                segment: AccountingSegment.ledger,
                              );
                            }
                            if (key == 'settle') {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.settlements,
                                arguments: ClubArgs(_clubId),
                              ).then((_) => _load());
                            }
                          },
                        ),
                        const SizedBox(height: 26),
                        const SectionTitle(title: '지금 확인해 주세요'),
                        const SizedBox(height: 12),
                        if (data.tasks.isEmpty)
                          const MoaEmptyCard(
                            title: '확인할 일이 없어요',
                            body: '가입과 회비, 정산이 생기면 여기에 모아둘게요.',
                            icon: Icons.inbox_outlined,
                          )
                        else
                          for (final task in data.tasks)
                            TaskCard(
                              task: task,
                              onTap: task.kind == 'join' ? _openInbox : null,
                            ),
                        const SizedBox(height: 18),
                        const SectionTitle(
                          title: '차곡차곡, 최근 기록',
                          action: '전체보기',
                        ),
                        if (data.activities.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: MoaEmptyCard(
                              title: '아직 기록이 없어요',
                              body: '회비와 지출이 쌓이면 차곡차곡 보여 드려요.',
                              icon: Icons.receipt_long_outlined,
                            ),
                          )
                        else
                          for (final item in data.activities)
                            ActivityRow(item: item),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: MoaBottomNav(
        selected: MoaTab.home,
        onSelected: (tab) {
          if (tab == MoaTab.reservation) {
            Navigator.pushNamed(
              context,
              AppRoutes.places,
              arguments: PlaceFlowArgs(clubId: _clubId),
            );
          }
          if (tab == MoaTab.attendance) {
            Navigator.pushNamed(
              context,
              AppRoutes.attendance,
              arguments: ClubArgs(_clubId),
            ).then((_) => _load());
          }
          if (tab == MoaTab.settlement) {
            openAccounting(context, _clubId);
          }
          if (tab == MoaTab.myPage) {
            Navigator.pushNamed(
              context,
              AppRoutes.myPage,
              arguments: ClubArgs(_clubId),
            );
          }
        },
      ),
    );
  }

  List<Widget> _events(HomeData data) {
    final events = todaysMeetings(uniqueMeetings(data.events), kstNow());
    if (events.isEmpty) {
      return const [
        MoaEmptyCard(
          title: '오늘 일정이 없어요',
          body: '새로 시작해 보세요. 모임을 만들면 여기에 보여 드려요.',
          icon: Icons.event_available_outlined,
        ),
      ];
    }
    return [
      for (final event in events) ...[
        EventCard(event: event, clubName: data.club.name),
        const SizedBox(height: 10),
      ],
    ];
  }
}
