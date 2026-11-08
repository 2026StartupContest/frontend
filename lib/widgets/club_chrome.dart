import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

Widget moaImage(
  String source, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  if (source.startsWith('data:image')) {
    final comma = source.indexOf(',');
    if (comma != -1) {
      try {
        return Image.memory(
          base64Decode(source.substring(comma + 1)),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      } catch (_) {}
    }
  }
  return Image.network(source, width: width, height: height, fit: fit, errorBuilder: errorBuilder);
}

class HomeIcon extends StatelessWidget {
  const HomeIcon(this.name, {super.key, this.size});

  final String name;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/home/$name.svg', width: size, height: size);
  }
}

class ClubMark extends StatelessWidget {
  const ClubMark({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 43,
    this.radius = 15,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty ? '모' : String.fromCharCode(name.runes.first);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? moaImage(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(letter),
              )
            : _fallback(letter),
      ),
    );
  }

  Widget _fallback(String letter) {
    return ColoredBox(
      color: AppColors.ink,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '$letter.',
            style: GoogleFonts.lora(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
              fontSize: size * 28 / 43,
              color: AppColors.caper,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class ClubTopBar extends StatelessWidget {
  const ClubTopBar({
    super.key,
    required this.club,
    required this.hasUnread,
    required this.showSettings,
    required this.onClub,
    required this.onNotices,
    this.onSettings,
  });

  final Club club;
  final bool hasUnread;
  final bool showSettings;
  final VoidCallback onClub;
  final VoidCallback onNotices;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onClub,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  ClubMark(name: club.name, imageUrl: club.imageUrl),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          club.tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.muted),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                club.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const HomeIcon('chevron_down'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _iconButton(asset: 'bell', onPressed: onNotices, dot: hasUnread),
          if (showSettings) _iconButton(asset: 'gear', onPressed: onSettings),
        ],
      ),
    );
  }

  Widget _iconButton({
    required String asset,
    required VoidCallback? onPressed,
    bool dot = false,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        icon: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            HomeIcon(asset),
            if (dot)
              const Positioned(
                right: 1,
                top: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.unreadDot, shape: BoxShape.circle),
                  child: SizedBox(width: 6, height: 6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MoaEmptyCard extends StatelessWidget {
  const MoaEmptyCard({super.key, required this.title, required this.body, required this.icon});

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.7),
          ),
        ),
        if (action != null)
          InkWell(
            onTap: onAction,
            child: Row(
              children: [
                Text(action!, style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: -0.4)),
                const SizedBox(width: 2),
                const HomeIcon('chevron_small'),
              ],
            ),
          ),
      ],
    );
  }
}

const meetingKindLabels = {'정기 출사', '뒤풀이', '회의', '기타'};

class MeetingArtBanner extends StatelessWidget {
  const MeetingArtBanner({super.key, required this.event, required this.clubName});

  final ClubEvent event;
  final String clubName;

  @override
  Widget build(BuildContext context) {
    final art = event.artTitle.isEmpty ? event.title : event.artTitle;
    final photo = event.imageUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    return Container(
      height: 119,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.art,
        borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPhoto) ...[
            moaImage(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.art),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xB3000000), Color(0x40000000), Color(0x00000000)],
                  stops: [0, 0.6, 1],
                ),
              ),
            ),
          ] else
            Positioned(
              right: 18,
              bottom: 2,
              child: Transform.rotate(
                angle: -0.22,
                child: const HomeIcon('art_star', size: 108),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(19, 18, hasPhoto ? 19 : 134, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meetingClubLabel(clubName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasPhoto ? const Color(0xE6FFFFFF) : AppColors.artMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  art,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lora(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: 1,
                    color: hasPhoto ? AppColors.white : AppColors.artInk,
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

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.clubName});

  final ClubEvent event;
  final String clubName;

  @override
  Widget build(BuildContext context) {
    final label = meetingClubLabel(clubName);
    final start = event.startsAt;
    final badge = start != null && isSameDay(start, kstNow()) ? '오늘 · $label' : label;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeetingArtBanner(event: event, clubName: clubName),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFEAF0E4), borderRadius: BorderRadius.circular(6)),
                      child: Text(badge, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    if (event.attendanceOpen)
                      const Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(color: AppColors.live, shape: BoxShape.circle),
                            child: SizedBox(width: 7, height: 7),
                          ),
                          SizedBox(width: 5),
                          Text('출석 진행 중', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(event.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                if (event.scheduleLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(event.scheduleLine, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
                if (event.attendeeInitials.isNotEmpty || event.attendeeSummary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < event.attendeeInitials.length && i < 3; i++)
                        Transform.translate(
                          offset: Offset(i == 0 ? 0 : -6.0 * i, 0),
                          child: _Initial(text: event.attendeeInitials[i], color: avatarColor(i)),
                        ),
                      if (event.attendeeSummary.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.attendeeSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF75816F)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF53634A))),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  static const _items = [
    ('dues', '회비 관리'),
    ('qr', 'QR 출석'),
    ('settle', 'N차 정산'),
    ('ledger', '회계 장부'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final item in _items)
          Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.chip),
                ),
                child: Center(child: HomeIcon(item.$1)),
              ),
              const SizedBox(height: 8),
              Text(item.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
      ],
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap});

  final HomeTask task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = switch (task.kind) {
      'dues' => (AppColors.taskCream, 'task_dues'),
      'settlement' => (AppColors.taskGreen, 'task_settle'),
      _ => (AppColors.taskBlue, 'task_join'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.chip),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: tone.$1, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: HomeIcon(tone.$2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: task.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          children: [
                            if (task.count != null)
                              TextSpan(
                                text: '  ${task.count}',
                                style: TextStyle(
                                  color: task.kind == 'dues' ? AppColors.copper : AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(task.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
                const HomeIcon('chevron'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.income ? AppColors.primary : AppColors.ink;
    final sign = item.income ? '+' : '−';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFEDF1E8), borderRadius: BorderRadius.circular(12)),
            child: Center(child: HomeIcon(item.income ? 'activity_in' : 'activity_out')),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(item.subtitle, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$sign${formatWon(item.amount.abs())}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 3),
              Text(item.amountNote, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

Color avatarColor(int index) {
  const colors = [Color(0xFFD9E3CB), Color(0xFFEADBCC), Color(0xFFE6DCAA), Color(0xFFDFE4EF)];
  return colors[index % colors.length];
}

class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final owner = ClubAccess.isOwner(role);
    final admin = role == ClubAccess.admin;
    final bg = owner ? AppColors.ink : admin ? AppColors.soft : AppColors.roleGrayBg;
    final fg = owner ? AppColors.caper : admin ? AppColors.primary : AppColors.roleGray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (owner) ...[
            const Icon(Icons.workspace_premium_outlined, size: 11, color: AppColors.caper),
            const SizedBox(width: 3),
          ],
          Text(ClubAccess.label(role), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.4)),
        ],
      ),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.initial, required this.index, this.size = 36});

  final String initial;
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: avatarColor(index), borderRadius: BorderRadius.circular(18)),
      child: Text(initial, style: const TextStyle(fontSize: 12, color: Color(0xFF53634A))),
    );
  }
}

Future<void> showMoaError(BuildContext context, Object error) async {
  if (!context.mounted) return;
  final raw = error.toString().replaceFirst('Bad state: ', '');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(raw)));
}
