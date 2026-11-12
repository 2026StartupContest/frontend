import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_proj/core/auth_error_message.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

class JoinRequestScreen extends StatefulWidget {
  const JoinRequestScreen({super.key, required this.deps, required this.club});

  final MoaDependencies deps;
  final Club club;

  @override
  State<JoinRequestScreen> createState() => _JoinRequestScreenState();
}

class _JoinRequestScreenState extends State<JoinRequestScreen> {
  late final TextEditingController _name;
  bool _paid = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.deps.auth.currentDisplayName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _message = '입금자명을 입력해 주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.requestJoin(
        uid: uid,
        userName: widget.deps.auth.currentDisplayName ?? _name.text,
        club: widget.club,
        depositName: _name.text,
        feeReported: _paid,
      );
      if (!mounted) return;
      await Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.joinPending,
        (_) => false,
        arguments: ClubArgs(widget.club.id),
      );
    } catch (error) {
      setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.club;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const MoaPageHeader(title: '가입 신청'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Container(
                    height: 110,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
                    child: const Align(
                      alignment: Alignment.bottomLeft,
                      child: Text('함께하는 모임', style: TextStyle(color: AppColors.caper, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(club.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        if (club.tagline.isNotEmpty) Text(club.tagline, style: const TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 6),
                        Text('구성원 ${club.memberCount}명 · 회장 ${club.ownerName}', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  if (club.feeAmount != null) ...[
                    const SizedBox(height: 18),
                    const Text('가입비 안내', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _line('가입비', formatWon(club.feeAmount!)),
                    if (club.bankLine != null) _line('입금 계좌', club.bankLine!),
                    if (club.accountHolder != null)
                      _line(
                        '예금주',
                        club.accountHolder!,
                        trailing: TextButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${club.bankLine ?? ''} ${club.accountHolder}'));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('계좌를 복사했어요.')));
                          },
                          child: const Text('계좌 복사'),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  MoaField(label: '입금자명', controller: _name),
                  CheckboxListTile(
                    value: _paid,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('가입비를 입금했어요'),
                    onChanged: (value) => setState(() => _paid = value ?? false),
                  ),
                  const Text(
                    '신청하면 입금 확인 중 상태가 되고, 회장이 입금을 확인하면 가입이 완료돼요.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(_message!, style: const TextStyle(color: AppColors.danger)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: MoaPrimaryButton(label: '가입 신청 보내기', busy: _busy, onPressed: _submit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value, {Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ?trailing,
        ],
      ),
    );
  }
}
