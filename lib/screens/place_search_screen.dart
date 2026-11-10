import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/moa_bottom_nav.dart';
import 'package:flutter_proj/widgets/place_widgets.dart';

class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({super.key, required this.clubId});

  final String clubId;

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final _query = TextEditingController(text: '홍대');
  PlaceCategory _category = PlaceCategory.restaurant;
  final _saved = <String>{};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<DummyPlace> get _places {
    final text = _query.text.trim();
    final aroundHongdae = text.isEmpty || text == '홍대';
    return [
      for (final place in dummyPlaces)
        if (place.category == _category &&
            (aroundHongdae || _matches(place, text)))
          place,
    ];
  }

  bool _matches(DummyPlace place, String text) {
    final haystack = '${place.name} ${place.cuisine} ${place.area}'
        .toLowerCase();
    return haystack.contains(text.toLowerCase());
  }

  void _open(DummyPlace place) {
    Navigator.pushNamed(
      context,
      AppRoutes.placeMenu,
      arguments: PlaceFlowArgs(clubId: widget.clubId, placeId: place.id),
    );
  }

  void _tab(MoaTab tab) {
    switch (tab) {
      case MoaTab.home:
        goClubHome(context, widget.clubId);
      case MoaTab.reservation:
        return;
      case MoaTab.attendance:
        Navigator.pushNamed(
          context,
          AppRoutes.attendance,
          arguments: ClubArgs(widget.clubId),
        );
      case MoaTab.settlement:
        return;
      case MoaTab.myPage:
        Navigator.pushNamed(
          context,
          AppRoutes.myPage,
          arguments: ClubArgs(widget.clubId),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = _places;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          SizedBox(
            height: 260 + top,
            child: _MapHeader(
              top: top,
              count: places.length,
              query: _query,
              onQuery: () => setState(() {}),
              onBack: () => Navigator.maybePop(context),
              onMore: () => placeDummyNotice(context, '예시 화면이라 더보기 메뉴는 없어요.'),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final item in placeCategories)
                        _Chip(
                          label: item.$2,
                          icon: item.$3,
                          selected: _category == item.$1,
                          onTap: () => setState(() => _category = item.$1),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '단체 예약 가능한 곳',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ),
                      const Text(
                        '거리순',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: -0.4,
                          color: AppColors.muted,
                        ),
                      ),
                      Icon(
                        Icons.expand_more,
                        size: 16,
                        color: AppColors.muted.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
                if (places.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 36, 24, 24),
                    child: Text(
                      '이 분류는 아직 예시가 없어요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  )
                else
                  for (final place in places)
                    _PlaceCard(
                      place: place,
                      saved: _saved.contains(place.id),
                      onSave: () => setState(() {
                        if (!_saved.add(place.id)) _saved.remove(place.id);
                      }),
                      onOpen: () => _open(place),
                    ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: MoaBottomNav(
        selected: MoaTab.reservation,
        onSelected: _tab,
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.top,
    required this.count,
    required this.query,
    required this.onQuery,
    required this.onBack,
    required this.onMore,
  });

  final double top;
  final int count;
  final TextEditingController query;
  final VoidCallback onQuery;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _DummyMap()),
        Positioned(
          top: top,
          left: 0,
          right: 0,
          height: 56,
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
              ),
              const Expanded(
                child: Text(
                  '모임 장소 찾기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: AppColors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: onMore,
                icon: const Icon(Icons.more_vert, color: AppColors.white),
              ),
            ],
          ),
        ),
        Positioned(
          top: top + 56,
          left: 12,
          right: 12,
          child: Material(
            color: AppColors.white,
            elevation: 2,
            shadowColor: const Color(0x1A2B4830),
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search, size: 16, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: query,
                      onChanged: (_) => onQuery(),
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: -0.4,
                        color: AppColors.muted,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: '지역, 장소 이름',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: AppColors.bud,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A2B4830),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: AppColors.ink,
                ),
                const SizedBox(width: 5),
                Text(
                  '홍대입구역 주변 · $count곳',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DummyMap extends StatelessWidget {
  const _DummyMap();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: AssetImage(placeMapAsset),
          fit: BoxFit.cover,
        ),
        ColoredBox(color: Color(0x731E2820)),
        Positioned(left: 170, top: 78, child: _Pin('1', filled: true)),
        Positioned(left: 275, top: 118, child: _Pin('2')),
        Positioned(left: 65, top: 118, child: _Pin('3')),
        Positioned(left: 196, top: 148, child: _UserDot()),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin(this.label, {this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.785398,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.white,
          border: Border.all(color: AppColors.primary),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x54246946),
              blurRadius: 4,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: 0.785398,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: filled ? AppColors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x333D7BE0), spreadRadius: 6)],
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF3D7BE0),
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 12, height: 12),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.white : placeChipInk;
    return Material(
      color: selected ? AppColors.primary : placeChipIdle,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: -0.4,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.saved,
    required this.onSave,
    required this.onOpen,
  });

  final DummyPlace place;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.chip)),
        ),
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${place.pin}. ${place.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                                color: AppColors.primary,
                              ),
                            ),
                            if (place.partner) ...[
                              const SizedBox(width: 6),
                              const PlacePartnerBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          place.meta,
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: -0.4,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: placeGreenNote,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '최대 ${place.capacity}명',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onSave,
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      size: 18,
                      color: saved ? AppColors.primary : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < place.photos.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.horizontal(
                          left: i == 0 ? const Radius.circular(8) : Radius.zero,
                          right: i == place.photos.length - 1
                              ? const Radius.circular(8)
                              : Radius.zero,
                        ),
                        child: Image.asset(
                          place.photos[i],
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(
                    '영업 중 · 리뷰 ${place.reviews}',
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: -0.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: placeSoft,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: onOpen,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Text(
                          '예약하기',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
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
