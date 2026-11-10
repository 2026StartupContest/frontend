import 'package:flutter/material.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';

const placeThumb = Color(0xFFF3E3CF);
const placeThumbInk = Color(0xFFA46B2C);
const placePartnerBg = Color(0xFFFFF2DF);
const placePartnerInk = Color(0xFF8A6A2C);
const placeChipIdle = Color(0xFFEAF0E2);
const placeChipInk = Color(0xFF6E7C64);
const placeSoft = Color(0xFFEAF1E0);
const placeField = Color(0xFFF9FAF6);
const placeHint = Color(0xFFA9B1A3);
const placeTimeOff = Color(0xFFF2F4EE);
const placeTimeOffInk = Color(0xFFC3CABB);
const placeTimeOn = Color(0xFFF1F7E8);
const placeCounter = Color(0xFFEEF3E7);
const placeGreenNote = Color(0xFFEAF0E4);

void placeDummyNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class PlaceHeadline extends StatelessWidget {
  const PlaceHeadline({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            height: 1.45,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            height: 1.8,
            letterSpacing: -0.4,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class PlacePanel extends StatelessWidget {
  const PlacePanel({
    super.key,
    required this.child,
    this.borderColor = AppColors.chip,
  });

  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class PlaceMark extends StatelessWidget {
  const PlaceMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: placeThumb,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.restaurant_outlined,
        size: size * 0.42,
        color: placeThumbInk,
      ),
    );
  }
}

class PlacePartnerBadge extends StatelessWidget {
  const PlacePartnerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: placePartnerBg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        '제휴',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: placePartnerInk,
        ),
      ),
    );
  }
}

class PlaceStatusBadge extends StatelessWidget {
  const PlaceStatusBadge(
    this.label, {
    super.key,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, letterSpacing: -0.4, color: foreground),
      ),
    );
  }
}

class PlaceMoneyLine extends StatelessWidget {
  const PlaceMoneyLine(
    this.label,
    this.value, {
    super.key,
    this.valueColor,
    this.strong = false,
    this.big = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: big ? 14 : 12,
              fontWeight: big ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: -0.4,
              color: AppColors.rowLabel,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 21 : (strong ? 14 : 12),
            fontWeight: big ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: big ? -0.6 : -0.4,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class PlaceCheck extends StatelessWidget {
  const PlaceCheck({super.key, required this.checked, this.size = 22});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: checked ? AppColors.primary : AppColors.line),
      ),
      child: checked
          ? Icon(Icons.check, size: size * 0.62, color: AppColors.white)
          : null,
    );
  }
}

class PlaceBottomBar extends StatelessWidget {
  const PlaceBottomBar({super.key, required this.child, this.top});

  final Widget child;
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        border: Border(top: BorderSide(color: AppColors.chip, width: 0.635)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (top != null) ...[top!, const SizedBox(height: 10)],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceNote extends StatelessWidget {
  const PlaceNote({
    super.key,
    required this.text,
    this.tone = PlaceNoteTone.info,
  });

  final String text;
  final PlaceNoteTone tone;

  @override
  Widget build(BuildContext context) {
    if (tone == PlaceNoteTone.info) {
      return AttendanceInfoNote(icon: 'clock', text: text);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: placeGreenNote,
        borderRadius: BorderRadius.circular(12),
      ),
      child: text.isEmpty
          ? const SizedBox.shrink()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.8,
                      letterSpacing: -0.4,
                      color: Color(0xFF6F7C68),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

enum PlaceNoteTone { info, green }

String placeWon(int value) => formatWon(value);

String placeMinusWon(int value) => '−${formatWon(value)}';
