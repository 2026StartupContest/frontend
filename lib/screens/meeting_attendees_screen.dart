import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

class MeetingAttendeesScreen extends StatefulWidget {
  const MeetingAttendeesScreen({super.key, required this.deps, required this.args});

  final MoaDependencies deps;
  final MeetingArgs args;

  @override
  State<MeetingAttendeesScreen> createState() => _MeetingAttendeesScreenState();
}

class _MeetingAttendeesScreenState extends State<MeetingAttendeesScreen> {
  List<ClubMember> _members = const [];
  final _selected = <String>{};
  String _query = '';
  bool _ready = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.args.selectedIds);
    _load();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final desk = await widget.deps.clubs.loadDesk(uid: uid, clubId: widget.args.clubId);
      if (!mounted) return;
      setState(() {
        _members = desk.members;
        _ready = true;
      });
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    }
  }

  List<ClubMember> get _visible {
    final query = _query.trim();
    if (query.isEmpty) return _members;
    return _members.where((member) => member.userName.contains(query)).toList();
  }

  Future<void> _save() async {
    final ids = _selected.toList();
    final eventId = widget.args.eventId;
    if (eventId == null) {
      Navigator.pop(context, ids);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.setMeetingAttendees(clubId: widget.args.clubId, eventId: eventId, attendeeIds: ids);
      if (mounted) Navigator.pop(context, ids);
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final allChecked = visible.isNotEmpty && visible.every((member) => _selected.contains(member.userId));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: !_ready
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                children: [
                  const MoaPageHeader(title: '참석 인원 설정'),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      children: [
                        Row(
                          children: [
                            Text('${_selected.length}명 선택됨', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            const Spacer(),
                            Text('전체 ${_members.length}명', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: '이름으로 찾기',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            filled: true,
                            fillColor: AppColors.white,
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: AppColors.chip)),
                          child: Column(
                            children: [
                              _row(
                                checked: allChecked,
                                onChanged: (value) {
                                  setState(() {
                                    if (value) {
                                      _selected.addAll(visible.map((member) => member.userId));
                                    } else {
                                      _selected.removeAll(visible.map((member) => member.userId));
                                    }
                                  });
                                },
                                child: const Text('전체 선택', style: TextStyle(color: AppColors.muted)),
                              ),
                              for (var i = 0; i < visible.length; i++)
                                _row(
                                  lined: i != visible.length - 1,
                                  checked: _selected.contains(visible[i].userId),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value) {
                                        _selected.add(visible[i].userId);
                                      } else {
                                        _selected.remove(visible[i].userId);
                                      }
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      MemberAvatar(initial: visible[i].initial, index: i),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(visible[i].userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                            Text(
                                              _selected.contains(visible[i].userId) ? '참석 예정' : visible[i].subtitle,
                                              style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      children: [
                        Text.rich(
                          TextSpan(
                            text: '${_selected.length}명',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                            children: const [TextSpan(text: ' 선택', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w400))],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: MoaPrimaryButton(label: '저장하기', busy: _busy, onPressed: _save)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _row({required bool checked, required ValueChanged<bool> onChanged, required Widget child, bool lined = true}) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: lined ? const Border(bottom: BorderSide(color: AppColors.chip)) : null),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: checked ? AppColors.primary : const Color(0xFFC9D2C1)),
              ),
              child: checked ? const Icon(Icons.check, size: 14, color: AppColors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
