import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum MoaTab { home, reservation, attendance, settlement, myPage }

class MoaBottomNav extends StatelessWidget {
  const MoaBottomNav({super.key, this.selected, this.onSelected});

  final MoaTab? selected;
  final ValueChanged<MoaTab>? onSelected;

  static const labels = ['홈', '예약', '출석', '회계', '마이페이지'];
  static const _barHeight = 78.0;
  static const _lift = 16.5;
  static const _muted = Color(0xFFA9B1A6);
  static const _pill = Color(0xFFDCF0E5);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: _barHeight + _lift + bottom,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            top: _lift,
            bottom: 0,
            child: ColoredBox(color: AppColors.white),
          ),
          SafeArea(
            top: false,
            child: SizedBox(
              height: _barHeight + _lift,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final tab in MoaTab.values) Expanded(child: _item(tab)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(MoaTab tab) {
    final isCenter = tab == MoaTab.attendance;
    return InkWell(
      key: ValueKey('nav-${tab.name}'),
      onTap: onSelected == null ? null : () => onSelected!(tab),
      child: SizedBox(
        height: _barHeight + _lift,
        child: isCenter ? _center() : _side(tab),
      ),
    );
  }

  Widget _side(MoaTab tab) {
    final isSelected = tab == selected;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: _barHeight,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (isSelected)
              Positioned(
                top: 9.8,
                child: Container(
                  width: 48,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _pill,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            Positioned(
              top: 14.7,
              child: Icon(
                _icon(tab),
                size: 20,
                color: isSelected ? AppColors.primary : _muted,
              ),
            ),
            Positioned(
              top: 42.2,
              left: 0,
              right: 0,
              child: Text(
                labels[tab.index],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _center() {
    final isSelected = selected == MoaTab.attendance;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 0,
          child: Container(
            width: 51.4,
            height: 51.4,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _pill : null,
              gradient: isSelected
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFAF3E8), Color(0xFFEFE2C8)],
                    ),
              border: Border.all(color: AppColors.white, width: 2.3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x265F4A20),
                  offset: Offset(0, 3.7),
                  blurRadius: 4.1,
                ),
              ],
            ),
            child: isSelected
                ? SvgPicture.asset('assets/attendance/nav_qr_selected.svg')
                : const Icon(Icons.qr_code_2, size: 24, color: AppColors.ink),
          ),
        ),
        const Positioned(
          top: 58.7,
          left: 0,
          right: 0,
          child: Text(
            '출석',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
        ),
      ],
    );
  }

  IconData _icon(MoaTab tab) {
    return switch (tab) {
      MoaTab.home => Icons.home_outlined,
      MoaTab.reservation => Icons.calendar_today_outlined,
      MoaTab.attendance => Icons.qr_code_2,
      MoaTab.settlement => Icons.credit_card_outlined,
      MoaTab.myPage => Icons.person_outline,
    };
  }
}
