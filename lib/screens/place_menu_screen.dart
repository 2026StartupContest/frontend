import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/place_widgets.dart';

class PlaceMenuScreen extends StatefulWidget {
  const PlaceMenuScreen({super.key, required this.args});

  final PlaceFlowArgs args;

  @override
  State<PlaceMenuScreen> createState() => _PlaceMenuScreenState();
}

class _PlaceMenuScreenState extends State<PlaceMenuScreen> {
  var _menu = true;

  DummyPlace get _place => placeById(widget.args.placeId!);

  void _reserve() {
    Navigator.pushNamed(
      context,
      AppRoutes.placeReserve,
      arguments: PlaceFlowArgs(clubId: widget.args.clubId, placeId: _place.id),
    );
  }

  void _list() {
    Navigator.pushNamed(
      context,
      AppRoutes.reservations,
      arguments: PlaceFlowArgs(clubId: widget.args.clubId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = _place;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: top),
              _MenuBar(onList: _list),
              SizedBox(
                height: 170,
                child: _SelectedMap(name: place.name, pin: place.pin),
              ),
            ],
          ),
          Positioned(
            top: top + 70 + 150,
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.white,
              elevation: 8,
              shadowColor: const Color(0x262B4830),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      children: [
                        Row(
                          children: [
                            Text(
                              place.name,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                              ),
                            ),
                            if (place.partner) ...[
                              const SizedBox(width: 7),
                              const PlacePartnerBadge(),
                            ],
                            const Spacer(),
                            Material(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () => Navigator.maybePop(context),
                                borderRadius: BorderRadius.circular(14),
                                child: const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          place.meta,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.7,
                            letterSpacing: -0.4,
                            color: AppColors.label,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Tab(
                              label: '메뉴',
                              selected: _menu,
                              onTap: () => setState(() => _menu = true),
                            ),
                            const SizedBox(width: 28),
                            _Tab(
                              label: '매장 정보',
                              selected: !_menu,
                              onTap: () => setState(() => _menu = false),
                            ),
                          ],
                        ),
                        const Divider(height: 1, color: AppColors.chip),
                        const SizedBox(height: 12),
                        if (_menu)
                          _MenuBody(place: place)
                        else
                          _StoreBody(place: place),
                        const SizedBox(height: 13),
                        _GroupBox(capacity: place.capacity),
                      ],
                    ),
                  ),
                  PlaceBottomBar(
                    child: AttendanceButton(
                      label: '단체 예약하기',
                      icon: 'calendar',
                      height: 48,
                      onPressed: _reserve,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuBar extends StatelessWidget {
  const _MenuBar({required this.onList});

  final VoidCallback onList;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
        child: Row(
          children: [
            AttendanceIconButton(
              icon: 'back',
              label: '뒤로',
              onPressed: () => Navigator.maybePop(context),
            ),
            const Expanded(
              child: Text(
                '모임 장소 찾기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            _ListChip(onTap: onList),
          ],
        ),
      ),
    );
  }
}

class _ListChip extends StatelessWidget {
  const _ListChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: placeSoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                SizedBox(width: 4),
                Text(
                  '예약',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedMap extends StatelessWidget {
  const _SelectedMap({required this.name, required this.pin});

  final String name;
  final int pin;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return OverflowBox(
                alignment: Alignment.topCenter,
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
                minHeight: 250,
                maxHeight: 250,
                child: Transform.translate(
                  offset: const Offset(0, -36),
                  child: Image(
                    image: const AssetImage(placeMapAsset),
                    width: constraints.maxWidth,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 16,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '홍대입구역 주변',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: AppColors.label,
                ),
              ),
            ),
          ),
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x262B4830),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      '$pin  $name',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(12, 6),
                    painter: _CaretPainter(),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(left: 211, top: 118, child: _Dot()),
        ],
      ),
    );
  }
}

class _CaretPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF3D7BE0),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x333D7BE0), spreadRadius: 6)],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: selected ? 14 : 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: -0.4,
            color: selected ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _MenuBody extends StatelessWidget {
  const _MenuBody({required this.place});

  final DummyPlace place;

  @override
  Widget build(BuildContext context) {
    final first = place.menus.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 144,
          child: Row(
            children: [
              Expanded(
                flex: 218,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(place.dishImage, fit: BoxFit.cover),
                      const Positioned(
                        left: 8,
                        top: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xF2FFFFFF),
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Text(
                              '이미지 예시',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                color: AppColors.label,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 114,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(place.storeImage, fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Text(
              first.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '예시',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: -0.4,
                color: AppColors.muted,
              ),
            ),
            const Spacer(),
            Text(
              formatWon(first.price),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          first.description,
          style: const TextStyle(
            fontSize: 11,
            height: 1.7,
            letterSpacing: -0.4,
            color: AppColors.label,
          ),
        ),
        if (place.menus.length > 1) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.chip),
          for (final menu in place.menus.skip(1))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.sample ? '${menu.name} · 예시' : menu.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          menu.description,
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: -0.4,
                            color: AppColors.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatWon(menu.price),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 13),
        const Text(
          '사진·메뉴·가격은 예시입니다.\n실제 구성과 금액은 매장에 확인해 주세요.',
          style: TextStyle(
            fontSize: 11,
            height: 1.45,
            letterSpacing: -0.4,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _StoreBody extends StatelessWidget {
  const _StoreBody({required this.place});

  final DummyPlace place;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('주소', place.address),
      ('영업', '17:00 – 23:00'),
      ('전화', place.phone),
      ('예약금', '1인 ${formatWon(placeDepositPerPerson)}'),
    ];
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    item.$1,
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: -0.4,
                      color: AppColors.rowLabel,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Text(
          '매장 정보도 예시입니다. 실제 영업 여부는 매장에 확인해 주세요.',
          style: TextStyle(
            fontSize: 11,
            height: 1.6,
            letterSpacing: -0.4,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _GroupBox extends StatelessWidget {
  const _GroupBox({required this.capacity});

  final int capacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: placeGreenNote,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, size: 22, color: AppColors.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '단체 예약 가능',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '예약 전 날짜와 인원을 확인해 주세요.',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: -0.4,
                    color: AppColors.label,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '최대 $capacity명',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
