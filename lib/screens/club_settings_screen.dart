import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/club_sheets.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

class ClubSettingsScreen extends StatefulWidget {
  const ClubSettingsScreen({super.key, required this.deps, required this.clubId});

  final MoaDependencies deps;
  final String clubId;

  @override
  State<ClubSettingsScreen> createState() => _ClubSettingsScreenState();
}

class _ClubSettingsScreenState extends State<ClubSettingsScreen> {
  ClubDesk? _desk;
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final desk = await widget.deps.clubs.loadDesk(uid: uid, clubId: widget.clubId);
      if (!mounted) return;
      if (!ClubAccess.showsSettings(desk.myRole)) {
        Navigator.pop(context);
        return;
      }
      setState(() {
        _desk = desk;
        _message = null;
      });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editProfile(Club club) async {
    final draft = await showDialog<_ClubProfileDraft>(
      context: context,
      builder: (context) => _ClubProfileDialog(club: club),
    );
    if (draft == null || !mounted) return;
    final name = draft.name.trim();
    if (name.isEmpty) {
      await showMoaError(context, StateError('동아리 이름을 입력해 주세요.'));
      return;
    }
    if (name == club.name && draft.image == null) return;
    await _run(() => widget.deps.clubs.updateClubName(clubId: club.id, name: name, image: draft.image));
  }

  Future<void> _editFee(Club club) async {
    final next = await showDialog<String>(
      context: context,
      builder: (context) => _FeeDialog(initial: club.feeAmount?.toString() ?? ''),
    );
    if (next == null || !mounted) return;
    await _run(() => widget.deps.clubs.updateFeeAmount(clubId: club.id, feeAmount: parseWon(next)));
  }

  Future<void> _delete(ClubDesk desk) async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    final ok = await showDeleteClubSheet(context, desk.club);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final next = await widget.deps.clubs.deleteClub(uid: uid, clubId: desk.club.id);
      if (!mounted) return;
      if (next == null) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.noClub, (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false, arguments: HomeArgs(next));
      }
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desk = _desk;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: desk == null
            ? Center(child: _message == null ? const CircularProgressIndicator(color: AppColors.primary) : Text(_message!))
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  const MoaPageHeader(title: '동아리 설정'),
                  _ProfileCard(
                    club: desk.club,
                    canEdit: ClubAccess.isOwner(desk.myRole),
                    onEdit: () => _editProfile(desk.club),
                  ),
                  const _Label('구성원'),
                  _Card(
                    children: [
                      _Row(
                        title: '구성원 · 권한 관리',
                        subtitle: '${desk.members.length}명 · 회장 1 · 관리자 ${desk.adminCount}',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.memberRoles,
                          arguments: ClubArgs(desk.club.id),
                        ).then((_) => _load()),
                      ),
                      _Row(
                        title: '가입 요청',
                        subtitle: '새 요청 ${desk.requests.length}건',
                        badge: desk.requests.isEmpty ? null : '${desk.requests.length}',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.joinInbox,
                          arguments: ClubArgs(desk.club.id),
                        ).then((_) => _load()),
                      ),
                      _InviteRow(
                        club: desk.club,
                        canReissue: ClubAccess.isOwner(desk.myRole),
                        onCopy: () async {
                          final code = desk.club.inviteCode;
                          if (code == null || code.isEmpty) return;
                          await Clipboard.setData(ClipboardData(text: code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('초대 코드를 복사했어요.')));
                          }
                        },
                        onReissue: () => _run(() => widget.deps.clubs.reissueInvite(clubId: desk.club.id)),
                      ),
                    ],
                  ),
                  const _Label('가입'),
                  _Card(
                    children: [
                      _SwitchRow(
                        title: '승인 후 가입',
                        subtitle: '회장이 신청을 확인한 뒤 들어와요',
                        value: desk.club.requiresApproval,
                        enabled: ClubAccess.isOwner(desk.myRole) && !_busy,
                        onChanged: (value) => _run(
                          () => widget.deps.clubs.updateJoinPolicy(
                            clubId: desk.club.id,
                            joinPolicy: value ? ClubOptions.approval : ClubOptions.open,
                          ),
                        ),
                      ),
                      _Row(
                        title: '가입비',
                        subtitle: desk.club.feeAmount == null ? '없음' : formatWon(desk.club.feeAmount!),
                        onTap: ClubAccess.isOwner(desk.myRole) ? () => _editFee(desk.club) : null,
                      ),
                    ],
                  ),
                  if (ClubAccess.isOwner(desk.myRole)) ...[
                    const _Label('회장 메뉴'),
                    _Card(
                      children: [
                        _Row(
                          title: '회장 넘기기',
                          subtitle: '다른 구성원에게 회장 권한을 넘겨요',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.memberRoles,
                            arguments: ClubArgs(desk.club.id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _delete(desk),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.dangerSolid,
                        backgroundColor: AppColors.dangerBg,
                        side: const BorderSide(color: AppColors.dangerBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('동아리 삭제하기', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '삭제하면 회비 · 정산 · 장부 기록이 모두 사라지고 되돌릴 수 없어요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.club, required this.canEdit, required this.onEdit});

  final Club club;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Row(
        children: [
          ClubMark(name: club.name, imageUrl: club.imageUrl, size: 56, radius: 19),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  '대표 이미지 · 이름은 회장만 바꿀 수 있어요',
                  style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.subtitle, this.onTap, this.badge});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.chip))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(6)),
                child: Text(badge!, style: const TextStyle(fontSize: 10, color: AppColors.copper, fontWeight: FontWeight.w700)),
              ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.bud),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.chip))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Switch(value: value, onChanged: enabled ? onChanged : null, activeThumbColor: AppColors.white, activeTrackColor: AppColors.primary),
        ],
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({
    required this.club,
    required this.canReissue,
    required this.onCopy,
    required this.onReissue,
  });

  final Club club;
  final bool canReissue;
  final VoidCallback onCopy;
  final VoidCallback onReissue;

  @override
  Widget build(BuildContext context) {
    final code = club.inviteCode ?? '';
    final until = club.inviteExpiresAt == null ? '' : ' · ${formatInviteUntil(club.inviteExpiresAt!)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('초대 코드', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  code.isEmpty ? '코드가 없어요' : '$code$until',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          _Tiny(label: '복사', onPressed: code.isEmpty ? null : onCopy),
          const SizedBox(width: 6),
          _Tiny(label: '재발급', onPressed: canReissue ? onReissue : null),
        ],
      ),
    );
  }
}

class _Tiny extends StatelessWidget {
  const _Tiny({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.soft,
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.bud,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _ClubProfileDraft {
  const _ClubProfileDraft({required this.name, this.image});

  final String name;
  final ImagePayload? image;
}

class _ClubProfileDialog extends StatefulWidget {
  const _ClubProfileDialog({required this.club});

  final Club club;

  @override
  State<_ClubProfileDialog> createState() => _ClubProfileDialogState();
}

class _ClubProfileDialogState extends State<_ClubProfileDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.club.name);
  Uint8List? _preview;
  ImagePayload? _image;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _preview = bytes;
        _image = ImagePayload(bytes: bytes, contentType: 'image/jpeg');
      });
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('동아리 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(19),
              child: _preview == null
                  ? ClubMark(name: widget.club.name, imageUrl: widget.club.imageUrl, size: 76, radius: 19)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.memory(_preview!, width: 76, height: 76, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 8),
            const Text('사진을 눌러 대표 이미지를 바꿔요', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: '동아리 이름'),
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        TextButton(onPressed: _save, child: const Text('저장')),
      ],
    );
  }

  void _save() {
    Navigator.pop(context, _ClubProfileDraft(name: _name.text, image: _image));
  }
}

class _FeeDialog extends StatefulWidget {
  const _FeeDialog({required this.initial});

  final String initial;

  @override
  State<_FeeDialog> createState() => _FeeDialogState();
}

class _FeeDialogState extends State<_FeeDialog> {
  late final TextEditingController _amount = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('가입비'),
      content: TextField(
        controller: _amount,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: '금액'),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        TextButton(onPressed: () => Navigator.pop(context, _amount.text.trim()), child: const Text('저장')),
      ],
    );
  }
}
