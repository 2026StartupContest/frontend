import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';

enum MoaTab { home, reservation, attendance, settlement, myPage }

class MoaBottomNav extends StatelessWidget {
  const MoaBottomNav({
    super.key,
    required this.selected,
    this.onSelected,
  });

  final MoaTab selected;
  final ValueChanged<MoaTab>? onSelected;

  static const labels = ['홈', '예약', '출석', '정산', '마이페이지'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 78,
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.chip)),
            ),
          ),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final tab in MoaTab.values) Expanded(child: _item(tab)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(MoaTab tab) {
    final isCenter = tab == MoaTab.attendance;
    final isSelected = tab == selected;
    final color = isSelected ? AppColors.primary : AppColors.bud;
    return InkWell(
      key: ValueKey('nav-${tab.name}'),
      onTap: onSelected == null ? null : () => onSelected!(tab),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isCenter)
            Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.attendanceIdle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_2,
                color: isSelected ? AppColors.white : AppColors.ink,
                size: 24,
              ),
            )
          else
            Container(
              width: 48,
              height: 30,
              margin: const EdgeInsets.only(bottom: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.caper : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(_icon(tab), size: 20, color: color),
            ),
          Text(
            labels[tab.index],
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
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
