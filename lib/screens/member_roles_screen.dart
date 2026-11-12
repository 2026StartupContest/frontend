import 'package:flutter/material.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/club_sheets.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

class MemberRolesScreen extends StatefulWidget {
  const MemberRolesScreen({super.key, required this.deps, required this.clubId});

  final MoaDependencies deps;
  final String clubId;

  @override
  State<MemberRolesScreen> createState() => _MemberRolesScreenState();
}

class _MemberRolesScreenState extends State<MemberRolesScreen> {
  ClubDesk? _desk;
  String? _message;
  String _query = '';

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
      if (mounted) setState(() => _desk = desk);
    } catch (error) {
      if (mounted) setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  List<ClubMember> _visible(ClubDesk desk) {
    final query = _query.trim();
    final members = desk.members.where((member) => query.isEmpty || member.userName.contains(query)).toList();
    members.sort((a, b) {
      final rank = ClubAccess.rank(a.role).compareTo(ClubAccess.rank(b.role));
      if (rank != 0) return rank;
      return a.userName.compareTo(b.userName);
    });
    return members;
  }

  Future<void> _openMember(ClubDesk desk, ClubMember member) async {
    if (!ClubAccess.isOwner(desk.myRole) || member.userId == desk.user.id || member.role == ClubAccess.owner) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      barrierColor: AppColors.dim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => _RoleSheet(
        member: member,
        myName: desk.user.name,
        onSave: (role) async {
          await widget.deps.clubs.setMemberRole(clubId: widget.clubId, userId: member.userId, role: role);
        },
        onTransfer: () async {
          await widget.deps.clubs.transferOwnership(
            clubId: widget.clubId,
            fromUserId: desk.user.id,
            toUserId: member.userId,
          );
        },
        onRemove: () async {
          await widget.deps.clubs.removeMember(clubId: widget.clubId, userId: member.userId);
        },
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final desk = _desk;
    final members = desk == null ? const <ClubMember>[] : _visible(desk);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: desk == null
            ? Center(child: _message == null ? const CircularProgressIndicator(color: AppColors.primary) : Text(_message!))
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  const MoaPageHeader(title: '구성원 · 권한'),
                  const Row(
                    children: [
                      Expanded(child: _Legend(title: '회장', body: '모든 권한\n가입 승인 · 역할 변경', filled: true)),
                      SizedBox(width: 8),
                      Expanded(child: _Legend(title: '관리자', body: '회비 · 출석 · 정산\n장부 관리')),
                      SizedBox(width: 8),
                      Expanded(child: _Legend(title: '일반', body: '내 회비 · 출석\n정산 확인', muted: true)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text('구성원 ${desk.members.length}명', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      const Text('역할순', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.muted),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: '이름으로 검색',
                      hintStyle: const TextStyle(color: AppColors.bud, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.bud),
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: AppColors.chip),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < members.length; i++)
                          _MemberRow(
                            member: members[i],
                            index: i,
                            mine: members[i].userId == desk.user.id,
                            showChange: ClubAccess.isOwner(desk.myRole) && members[i].role != ClubAccess.owner,
                            onTap: () => _openMember(desk, members[i]),
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

class _Legend extends StatelessWidget {
  const _Legend({required this.title, required this.body, this.filled = false, this.muted = false});

  final String title;
  final String body;
  final bool filled;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoleChip(role: filled ? ClubAccess.owner : muted ? ClubAccess.member : ClubAccess.admin),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 10, height: 1.45, color: AppColors.muted, letterSpacing: -0.4)),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.index,
    required this.mine,
    required this.showChange,
    required this.onTap,
  });

  final ClubMember member;
  final int index;
  final bool mine;
  final bool showChange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: showChange ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.chip))),
        child: Row(
          children: [
            MemberAvatar(initial: member.initial, index: index),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(member.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                      if (mine) const Text('  (나)', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                      if (!ClubAccess.isOwner(member.role)) ...[
                        const SizedBox(width: 6),
                        RoleChip(role: member.role),
                      ],
                    ],
                  ),
                  if (member.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(member.subtitle, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  ],
                ],
              ),
            ),
            if (ClubAccess.isOwner(member.role))
              const RoleChip(role: ClubAccess.owner)
            else if (showChange)
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.soft,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('변경', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleSheet extends StatefulWidget {
  const _RoleSheet({
    required this.member,
    required this.myName,
    required this.onSave,
    required this.onTransfer,
    required this.onRemove,
  });

  final ClubMember member;
  final String myName;
  final Future<void> Function(String role) onSave;
  final Future<void> Function() onTransfer;
  final Future<void> Function() onRemove;

  @override
  State<_RoleSheet> createState() => _RoleSheetState();
}

class _RoleSheetState extends State<_RoleSheet> {
  late String _role = widget.member.role == ClubAccess.admin ? ClubAccess.admin : ClubAccess.member;
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await widget.onSave(_role);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _transfer() async {
    final ok = await showTransferSheet(
      context: context,
      targetName: widget.member.userName,
      targetRole: widget.member.role,
      myName: widget.myName,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onTransfer();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final ok = await showRemoveMemberSheet(context: context, member: widget.member);
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onRemove();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 34,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: const Color(0xFFD5DCCF), borderRadius: BorderRadius.circular(10)),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text('${widget.member.userName}님의 역할', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Text('역할에 따라 할 수 있는 일이 달라져요.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          _Choice(
            title: '관리자',
            body: '회비 입금 확인, QR 출석, 정산 확정, 장부 기록을 할 수 있어요.',
            selected: _role == ClubAccess.admin,
            onTap: () => setState(() => _role = ClubAccess.admin),
          ),
          const SizedBox(height: 8),
          _Choice(
            title: '일반',
            body: '내 회비 · 출석 · 정산만 확인할 수 있어요.',
            selected: _role == ClubAccess.member,
            onTap: () => setState(() => _role = ClubAccess.member),
          ),
          const SizedBox(height: 14),
          MoaPrimaryButton(label: '변경 저장하기', busy: _busy, onPressed: _role == widget.member.role ? null : _save),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('회장 권한', style: TextStyle(fontSize: 12, color: AppColors.muted))),
          ),
          OutlinedButton(
            onPressed: _busy ? null : _transfer,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.lineStrong),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('${widget.member.userName}님에게 회장 넘기기', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Text(
            '회장은 한 명만 있을 수 있어요. 넘기면 ${widget.myName}님은 관리자가 돼요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          Center(
            child: TextButton(
              onPressed: _busy ? null : _remove,
              child: const Text('동아리에서 내보내기', style: TextStyle(color: AppColors.dangerSolid, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.title, required this.body, required this.selected, required this.onTap});

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.soft : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.chip),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.primary : AppColors.bud, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
