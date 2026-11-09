import 'package:flutter/material.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

enum _JoinFilter { all, reported, unpaid }

class JoinInboxScreen extends StatefulWidget {
  const JoinInboxScreen({super.key, required this.deps, required this.clubId});

  final MoaDependencies deps;
  final String clubId;

  @override
  State<JoinInboxScreen> createState() => _JoinInboxScreenState();
}

class _JoinInboxScreenState extends State<JoinInboxScreen> {
  ClubDesk? _desk;
  String? _message;
  _JoinFilter _filter = _JoinFilter.all;
  final _selected = <String>{};
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
      setState(() {
        _desk = desk;
        _selected.removeWhere((id) => desk.requests.every((request) => request.userId != id));
      });
    } catch (error) {
      if (mounted) setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  List<Membership> _visible(ClubDesk desk) {
    return desk.requests.where((request) {
      return switch (_filter) {
        _JoinFilter.all => true,
        _JoinFilter.reported => request.feeReported,
        _JoinFilter.unpaid => !request.feeReported,
      };
    }).toList();
  }

  Future<void> _decide(bool approve) async {
    if (_selected.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final ids = _selected.toList();
      if (approve) {
        await widget.deps.clubs.approveJoins(clubId: widget.clubId, userIds: ids);
      } else {
        await widget.deps.clubs.rejectJoins(clubId: widget.clubId, userIds: ids);
      }
      _selected.clear();
      await _load();
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desk = _desk;
    final requests = desk == null ? const <Membership>[] : _visible(desk);
    final owner = desk != null && ClubAccess.isOwner(desk.myRole);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: desk == null
            ? Center(child: _message == null ? const CircularProgressIndicator(color: AppColors.primary) : Text(_message!))
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      children: [
                        const MoaPageHeader(title: '가입 요청'),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '새 가입 요청 ${desk.requests.length}건',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(6)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium_outlined, size: 11, color: AppColors.caper),
                                  SizedBox(width: 3),
                                  Text('회장 전용', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.caper)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 7,
                          children: [
                            _Chip(
                              label: '전체 ${desk.requests.length}',
                              selected: _filter == _JoinFilter.all,
                              onTap: () => setState(() => _filter = _JoinFilter.all),
                            ),
                            _Chip(
                              label: '입금 신고 ${desk.reportedCount}',
                              selected: _filter == _JoinFilter.reported,
                              onTap: () => setState(() => _filter = _JoinFilter.reported),
                            ),
                            _Chip(
                              label: '미입금 ${desk.unpaidCount}',
                              selected: _filter == _JoinFilter.unpaid,
                              onTap: () => setState(() => _filter = _JoinFilter.unpaid),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(color: AppColors.chip),
                          ),
                          child: Column(
                            children: [
                              if (owner)
                                _CheckRow(
                                  checked: requests.isNotEmpty && requests.every((request) => _selected.contains(request.userId)),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value) {
                                        _selected.addAll(requests.map((request) => request.userId));
                                      } else {
                                        _selected.removeAll(requests.map((request) => request.userId));
                                      }
                                    });
                                  },
                                  child: const Text('전체 선택', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                                ),
                              for (var i = 0; i < requests.length; i++)
                                _RequestRow(
                                  request: requests[i],
                                  index: i,
                                  checked: _selected.contains(requests[i].userId),
                                  selectable: owner,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value) {
                                        _selected.add(requests[i].userId);
                                      } else {
                                        _selected.remove(requests[i].userId);
                                      }
                                    });
                                  },
                                ),
                              if (requests.isEmpty)
                                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('요청이 없어요')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.infoNote, borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.verified_user_outlined, size: 16, color: AppColors.infoText),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '계좌에서 실제 입금을 확인한 뒤 승인해 주세요. 승인하면 신청자에게 바로 알림이 가요.',
                                  style: TextStyle(fontSize: 11, height: 1.5, color: AppColors.infoText),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (owner)
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                      decoration: const BoxDecoration(
                        color: Color(0xF2FFFFFF),
                        border: Border(top: BorderSide(color: AppColors.chip)),
                      ),
                      child: Row(
                        children: [
                          Text.rich(
                            TextSpan(
                              text: '${_selected.length}명',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                              children: const [TextSpan(text: ' 선택', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w400))],
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: _selected.isEmpty || _busy ? null : () => _decide(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: Color(0xFFD9E1D1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('거절'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _selected.isEmpty || _busy ? null : () => _decide(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(120, 46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _busy
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                                : const Text('승인하기'),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFEAF0E2),
      labelStyle: TextStyle(fontSize: 11, color: selected ? AppColors.white : const Color(0xFF6E7C64)),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.checked, required this.onChanged, required this.child});

  final bool checked;
  final ValueChanged<bool> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.chip))),
        child: Row(
          children: [
            _Box(checked: checked),
            const SizedBox(width: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.index,
    required this.checked,
    required this.selectable,
    required this.onChanged,
  });

  final Membership request;
  final int index;
  final bool checked;
  final bool selectable;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final when = request.requestedAt == null ? '' : formatNoticeTime(request.requestedAt!);
    final detail = request.feeReported
        ? '$when · 입금자명 ${request.depositName ?? request.userName}'
        : '$when · 아직 입금 신고 전';
    final body = Row(
        children: [
          MemberAvatar(initial: request.userName.isEmpty ? '모' : String.fromCharCode(request.userName.runes.first), index: index),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(detail.trim(), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: request.feeReported ? AppColors.peach : AppColors.unpaidBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              request.feeReported ? '입금 신고' : '미입금',
              style: TextStyle(fontSize: 10, color: request.feeReported ? AppColors.copper : AppColors.unpaidText),
            ),
          ),
        ],
      );
    if (!selectable) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.chip))),
        child: body,
      );
    }
    return _CheckRow(checked: checked, onChanged: onChanged, child: body);
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: checked ? AppColors.primary : const Color(0xFFC9D2C1)),
      ),
      child: checked ? const Icon(Icons.check, size: 14, color: AppColors.white) : null,
    );
  }
}
