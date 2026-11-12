import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AttendanceIcon extends StatelessWidget {
  const AttendanceIcon(this.name, {super.key, this.size});

  final String name;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/attendance/$name.svg',
      width: size,
      height: size,
    );
  }
}

class AttendanceAppBar extends StatelessWidget {
  const AttendanceAppBar({
    super.key,
    this.title,
    this.onBack,
    this.trailing,
    this.dark = false,
    this.close = false,
  });

  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool dark;

  /// 뒤로가기 화살표 대신 닫기 아이콘을 씁니다.
  final bool close;

  @override
  Widget build(BuildContext context) {
    final icon = close ? 'close' : (dark ? 'back_white' : 'back');
    return SizedBox(
      height: 70,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
        child: Row(
          children: [
            AttendanceIconButton(
              icon: icon,
              label: close ? '닫기' : '뒤로',
              onPressed: onBack ?? () => Navigator.maybePop(context),
            ),
            Expanded(
              child: title == null
                  ? const SizedBox.shrink()
                  : Text(
                      title!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: dark ? AppColors.white : AppColors.ink,
                      ),
                    ),
            ),
            SizedBox(width: 44, height: 44, child: trailing),
          ],
        ),
      ),
    );
  }
}

class AttendanceIconButton extends StatelessWidget {
  const AttendanceIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        icon: AttendanceIcon(icon),
      ),
    );
  }
}

class LiveDot extends StatelessWidget {
  const LiveDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.live,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x333CB371), spreadRadius: 3)],
      ),
    );
  }
}

class LiveCaption extends StatelessWidget {
  const LiveCaption(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LiveDot(),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            height: 1.8,
            letterSpacing: -0.4,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class AttendanceProgress extends StatelessWidget {
  const AttendanceProgress({
    super.key,
    required this.value,
    this.height = 7,
    this.color = AppColors.primary,
  });

  final double value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: AppColors.track,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clamped,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AttendanceCard extends StatelessWidget {
  const AttendanceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 17.6, vertical: 3.6),
    this.radius = 19,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.chip),
      ),
      child: child,
    );
  }
}

const attendanceRowBorder = Border(
  bottom: BorderSide(color: AppColors.chip, width: 0.635),
);

/// 왼쪽에 항목 이름, 오른쪽에 값을 놓는 정보 카드입니다.
class AttendanceInfoCard extends StatelessWidget {
  const AttendanceInfoCard({super.key, required this.rows});

  /// (항목, 값, 값 색)
  final List<(String, String, Color?)> rows;

  @override
  Widget build(BuildContext context) {
    return AttendanceCard(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: i == rows.length - 1 ? null : attendanceRowBorder,
              ),
              child: Row(
                children: [
                  Text(
                    rows[i].$1,
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: -0.4,
                      color: AppColors.rowLabel,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                        color: rows[i].$3 ?? AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 모임의 참석 대상 순서로 아바타 색을 정해서 화면이 달라도 같은 색을 씁니다.
Color attendeeColor(ClubEvent event, String userId) {
  final index = event.attendeeIds.indexOf(userId);
  return avatarColor(index < 0 ? 0 : index);
}

class AttendanceAvatar extends StatelessWidget {
  const AttendanceAvatar({
    super.key,
    required this.initial,
    required this.color,
    this.size = 36,
    this.bordered = false,
  });

  final String initial;
  final Color color;
  final double size;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: bordered ? Border.all(color: AppColors.white) : null,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size >= 36 ? 12 : 10,
          letterSpacing: -0.4,
          color: const Color(0xFF53634A),
        ),
      ),
    );
  }
}

/// 26px 아바타를 6px씩 겹쳐 놓습니다.
class AttendanceAvatarStack extends StatelessWidget {
  const AttendanceAvatarStack({super.key, required this.avatars});

  /// (이니셜, 색)
  final List<(String, Color)> avatars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < avatars.length; i++)
          Align(
            widthFactor: i == 0 ? 1 : 20 / 26,
            alignment: Alignment.centerRight,
            child: AttendanceAvatar(
              initial: avatars[i].$1,
              color: avatars[i].$2,
              size: 26,
              bordered: true,
            ),
          ),
      ],
    );
  }
}

class AttendanceMemberRow extends StatelessWidget {
  const AttendanceMemberRow({
    super.key,
    required this.initial,
    required this.color,
    required this.name,
    required this.caption,
    this.trailing,
    this.last = false,
  });

  final String initial;
  final Color color;
  final String name;
  final String caption;
  final Widget? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: last ? null : attendanceRowBorder),
      child: Row(
        children: [
          AttendanceAvatar(initial: initial, color: color),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: -0.4,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 11), trailing!],
        ],
      ),
    );
  }
}

enum AttendanceBadgeTone { present, manual, open, neutral, absent }

class AttendanceBadge extends StatelessWidget {
  const AttendanceBadge({super.key, required this.label, required this.tone});

  final String label;
  final AttendanceBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, weight) = switch (tone) {
      AttendanceBadgeTone.present => (
        AppColors.presentBg,
        AppColors.presentText,
        FontWeight.w400,
      ),
      AttendanceBadgeTone.manual => (
        AppColors.peach,
        AppColors.copper,
        FontWeight.w400,
      ),
      AttendanceBadgeTone.open => (
        AppColors.peach,
        AppColors.copper,
        FontWeight.w600,
      ),
      AttendanceBadgeTone.neutral => (
        const Color(0xFFEEF0EA),
        AppColors.roleGray,
        FontWeight.w600,
      ),
      AttendanceBadgeTone.absent => (
        AppColors.unpaidBg,
        AppColors.unpaidText,
        FontWeight.w400,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: weight,
          letterSpacing: -0.4,
          color: foreground,
        ),
      ),
    );
  }
}

enum AttendanceButtonTone { primary, soft, outline, white }

class AttendanceButton extends StatelessWidget {
  const AttendanceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = AttendanceButtonTone.primary,
    this.icon,
    this.iconSize = 18,
    this.busy = false,
    this.height = 46,
  });

  final String label;
  final VoidCallback? onPressed;
  final AttendanceButtonTone tone;

  /// `assets/attendance`의 SVG 이름입니다.
  final String? icon;
  final double iconSize;
  final bool busy;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      AttendanceButtonTone.primary => (AppColors.primary, AppColors.white),
      AttendanceButtonTone.soft => (AppColors.soft, AppColors.primary),
      AttendanceButtonTone.outline => (AppColors.white, AppColors.primary),
      AttendanceButtonTone.white => (AppColors.white, AppColors.primary),
    };
    final outline = tone == AttendanceButtonTone.outline;
    final enabled = onPressed != null && !busy;
    return Opacity(
      opacity: enabled || busy ? 1 : 0.6,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: outline
              ? const BorderSide(color: Color(0xFFD9E1D1))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: height,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          AttendanceIcon(icon!, size: iconSize),
                          SizedBox(width: outline ? 6 : 7),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: outline ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 화면 아래에 붙는 버튼 영역입니다.
class AttendanceBottomBar extends StatelessWidget {
  const AttendanceBottomBar({super.key, required this.children});

  final List<Widget> children;

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
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 9),
                Expanded(child: children[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceInfoNote extends StatelessWidget {
  const AttendanceInfoNote({super.key, required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15.5),
      decoration: BoxDecoration(
        color: AppColors.infoNote,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5.6),
            child: AttendanceIcon(icon),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                height: 1.8,
                letterSpacing: -0.4,
                color: AppColors.infoText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceSectionTitle extends StatelessWidget {
  const AttendanceSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
      ),
    );
  }
}

/// 손잡이와 닫기 버튼이 있는 바텀시트 틀입니다.
class AttendanceSheet extends StatelessWidget {
  const AttendanceSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 11, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.handle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child,
                ],
              ),
            ),
            Positioned(
              top: 14,
              right: 12,
              child: AttendanceIconButton(
                icon: 'close',
                label: '닫기',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showAttendanceSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.dim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => AttendanceSheet(child: builder(context)),
  );
}

/// 큰 아이콘, 제목, 설명을 가운데에 놓는 결과 안내입니다.
class AttendanceStatusHero extends StatelessWidget {
  const AttendanceStatusHero({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.lines,
    this.topPadding = 44,
  });

  final String icon;
  final Color iconBackground;
  final String title;
  final List<String> lines;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 8),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(26),
            ),
            child: AttendanceIcon(icon),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              height: 1.45,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 7.3),
          Text(
            lines.join('\n'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.8,
              letterSpacing: -0.4,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
