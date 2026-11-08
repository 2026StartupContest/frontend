import 'package:flutter/material.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';

Future<void> showNoticeSheet(BuildContext context, List<ClubNotice> notices) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.dim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              const _Handle(),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '새로운 소식',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                '놓치지 않도록 모아뒀어요. 읽지 않은 알림은 초록 점으로 표시돼요.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              if (notices.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: MoaEmptyCard(
                    title: '새로운 소식이 없어요',
                    body: '출석, 가입, 회비 알림이 생기면 여기에 모아둘게요.',
                    icon: Icons.notifications_none_rounded,
                  ),
                )
              else
                for (final notice in notices) _NoticeTile(notice: notice),
            ],
          );
        },
      );
    },
  );
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.notice});

  final ClubNotice notice;

  @override
  Widget build(BuildContext context) {
    final tone = switch (notice.kind) {
      'join' => (AppColors.taskBlue, Icons.person_add_alt_1_outlined),
      'dues' => (AppColors.taskCream, Icons.credit_card_outlined),
      'settlement' => (AppColors.taskGreen, Icons.grid_view_rounded),
      _ => (AppColors.soft, Icons.menu_book_outlined),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.chip),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tone.$1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tone.$2, color: AppColors.ink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notice.body.trim().isEmpty
                      ? formatNoticeTime(notice.createdAt)
                      : notice.body.trim(),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (notice.unread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0E4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '새 알림',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showClubSwitcher({
  required BuildContext context,
  required List<ClubOption> options,
  required Future<void> Function(ClubOption option) onPrimary,
  required void Function(ClubOption option) onOpen,
  required VoidCallback onCreate,
  required VoidCallback onJoin,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.dim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (sheetContext) {
      var current = options;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Handle(),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '내 동아리',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text(
                  '별표한 동아리가 앱을 열 때 가장 먼저 보여요.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                for (final option in current)
                  _ClubRow(
                    option: option,
                    onOpen: () {
                      Navigator.pop(sheetContext);
                      onOpen(option);
                    },
                    onPrimary: option.isPending
                        ? null
                        : () async {
                            try {
                              await onPrimary(option);
                              setSheetState(() {
                                current = [
                                  for (final item in current)
                                    ClubOption(
                                      club: item.club,
                                      role: item.role,
                                      status: item.status,
                                      primary: item.club.id == option.club.id,
                                    ),
                                ];
                              });
                            } catch (_) {}
                          },
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _SheetAction(
                        icon: Icons.add,
                        label: '새 동아리 만들기',
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          onCreate();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SheetAction(
                        icon: Icons.arrow_forward,
                        label: '코드로 가입',
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          onJoin();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _ClubRow extends StatelessWidget {
  const _ClubRow({
    required this.option,
    required this.onOpen,
    required this.onPrimary,
  });

  final ClubOption option;
  final VoidCallback onOpen;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final subtitle = option.isPending
        ? '가입 승인 대기 중'
        : '${ClubAccess.label(option.role)} · ${option.club.memberCount}명';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.chip),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClubMark(
                name: option.club.name,
                imageUrl: option.club.imageUrl,
                size: 44,
                radius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.club.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (option.isPending)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.peach,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '입금 확인 중',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.copper,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (option.primary)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '대표',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: onPrimary,
                      icon: Icon(
                        option.primary
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: option.primary
                            ? const Color(0xFFC6A15B)
                            : AppColors.bud,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.white,
        side: const BorderSide(color: Color(0xFFD7E0CF)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

Future<bool> showDeleteClubSheet(BuildContext context, Club club) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.dim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => _DeleteClubSheet(club: club),
  );
  return confirmed ?? false;
}

class _DeleteClubSheet extends StatefulWidget {
  const _DeleteClubSheet({required this.club});

  final Club club;

  @override
  State<_DeleteClubSheet> createState() => _DeleteClubSheetState();
}

class _DeleteClubSheetState extends State<_DeleteClubSheet> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _name.text.trim() == widget.club.name;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Handle(),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close),
              ),
            ),
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFFBE9E3),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.dangerSolid,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.club.name}를\n삭제할까요?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.35,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '회장만 할 수 있고, 삭제하면 되돌릴 수 없어요.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            _ImpactCard(memberCount: widget.club.memberCount),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '확인을 위해 동아리 이름을 입력해 주세요',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: widget.club.name,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFFD9E1D1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton(
                    onPressed: ready
                        ? () => Navigator.pop(context, true)
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.dangerSolid,
                      disabledBackgroundColor: AppColors.dangerSolid.withValues(
                        alpha: 0.35,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '동아리 삭제하기',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.memberCount});

  final int memberCount;

  @override
  Widget build(BuildContext context) {
    const rows = [('회비 · 장부 기록', '모두 삭제'), ('정산 · 출석 기록', '모두 삭제')];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(
        children: [
          _impact('구성원 $memberCount명', '모두 동아리에서 나가요', bordered: true),
          for (final row in rows)
            _impact(row.$1, row.$2, bordered: row != rows.last),
        ],
      ),
    );
  }

  Widget _impact(String label, String value, {required bool bordered}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: bordered
            ? const Border(bottom: BorderSide(color: AppColors.chip))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6B5A)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

Future<bool> showTransferSheet({
  required BuildContext context,
  required String targetName,
  required String targetRole,
  required String myName,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.dim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Handle(),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close),
              ),
            ),
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFFBE9E3),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.dangerSolid,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '$targetName님에게\n회장을 넘길까요?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '넘기면 $myName님은 관리자가 돼요.\n다시 받으려면 새 회장이 넘겨야 해요.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            _ImpactCardRows(
              rows: [
                ('새 회장', '$targetName (현재 ${ClubAccess.label(targetRole)})'),
                ('$myName님', '회장 → 관리자'),
                ('알림', '전체 구성원에게 안내'),
              ],
            ),
            const SizedBox(height: 14),
            _ConfirmButtons(
              cancel: '취소',
              confirm: '회장 넘기기',
              onConfirm: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
    },
  );
  return confirmed ?? false;
}

Future<bool> showRemoveMemberSheet({
  required BuildContext context,
  required ClubMember member,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.dim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      final unpaid = member.unpaidDues == null ? '없음' : '${member.unpaidDues}건';
      final unsettled = member.unsettledAmount == null
          ? '없음'
          : formatWon(member.unsettledAmount!);
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Handle(),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close),
              ),
            ),
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFFBE9E3),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.logout,
                color: AppColors.dangerSolid,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${member.userName}님을\n내보낼까요?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '내보내도 지난 회비 · 정산 기록은 장부에 남아요.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            _ImpactCardRows(
              rows: [
                ('미납 회비', unpaid),
                ('미정산 금액', unsettled),
                ('다시 가입', '초대 코드로 가능'),
              ],
            ),
            const SizedBox(height: 14),
            _ConfirmButtons(
              cancel: '취소',
              confirm: '내보내기',
              onConfirm: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
    },
  );
  return confirmed ?? false;
}

class _ImpactCardRows extends StatelessWidget {
  const _ImpactCardRows({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.chip)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5F6B5A),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

Future<bool> showLeaveAccountSheet(
  BuildContext context, {
  required String ownedLine,
  required String joinedLine,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.dim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) =>
        _LeaveAccountSheet(ownedLine: ownedLine, joinedLine: joinedLine),
  );
  return confirmed ?? false;
}

class _LeaveAccountSheet extends StatelessWidget {
  const _LeaveAccountSheet({required this.ownedLine, required this.joinedLine});

  final String ownedLine;
  final String joinedLine;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 11, 24, 32 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Handle(),
                const SizedBox(height: 8),
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE9E3),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppColors.dangerSolid,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '정말 탈퇴할까요?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    letterSpacing: -1,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '탈퇴하면 계정과 내 정보가 모두 삭제돼요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.8,
                    letterSpacing: -0.4,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: AppColors.chip),
                  ),
                  child: Column(
                    children: [
                      _LeaveImpactRow(
                        label: '회장인 동아리',
                        value: ownedLine,
                        bordered: true,
                      ),
                      _LeaveImpactRow(label: '가입한 동아리', value: joinedLine),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: AppColors.primary,
                          backgroundColor: AppColors.white,
                          side: const BorderSide(color: Color(0xFFD9E1D1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor: AppColors.dangerSolid,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('탈퇴하기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close, size: 22, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveImpactRow extends StatelessWidget {
  const _LeaveImpactRow({
    required this.label,
    required this.value,
    this.bordered = false,
  });

  final String label;
  final String value;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: bordered
            ? const Border(
                bottom: BorderSide(color: AppColors.chip, width: 0.6),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: -0.4,
              color: Color(0xFF5F6B5A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
                letterSpacing: -0.4,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButtons extends StatelessWidget {
  const _ConfirmButtons({
    required this.cancel,
    required this.confirm,
    required this.onConfirm,
  });

  final String cancel;
  final String confirm;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: Color(0xFFD9E1D1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              cancel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: FilledButton(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.dangerSolid,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              confirm,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 4,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFD5DCCF),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
