import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_proj/core/auth_error_message.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class JoinCodeScreen extends StatefulWidget {
  const JoinCodeScreen({super.key, required this.deps});

  final MoaDependencies deps;

  @override
  State<JoinCodeScreen> createState() => _JoinCodeScreenState();
}

class _JoinCodeScreenState extends State<JoinCodeScreen> {
  final _controller = TextEditingController();
  ClubPreview? _preview;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookup(String raw) async {
    final code = raw.trim().toUpperCase();
    _controller.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length.clamp(0, 6)),
    );
    if (code.length < 6) {
      setState(() {
        _preview = null;
        _message = null;
      });
      return;
    }
    setState(() => _busy = true);
    try {
      final preview = await widget.deps.clubs.findByCode(code);
      setState(() {
        _preview = preview;
        _message = preview == null ? '코드를 찾을 수 없거나 만료됐어요.' : null;
      });
    } catch (error) {
      setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final preview = _preview;
    final uid = widget.deps.auth.currentUid;
    if (preview == null || uid == null) return;
    if (preview.club.requiresApproval) {
      await Navigator.pushNamed(context, AppRoutes.joinRequest, arguments: preview.club);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.joinImmediately(
        uid: uid,
        userName: widget.deps.auth.currentDisplayName ?? '회원',
        club: preview.club,
      );
      if (!mounted) return;
      await Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
        arguments: HomeArgs(preview.club.id),
      );
    } catch (error) {
      setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const MoaPageHeader(title: '동아리 가입하기'),
            const Text('초대 코드를 입력해 주세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('회장에게 받은 6자리 코드를 입력하면 동아리를 찾아드려요.', style: TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 20),
            Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 6; i++)
                      Container(
                        width: 46,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Text(
                          i < _controller.text.length ? _controller.text[i] : '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: _lookup,
                  ),
                ),
              ],
            ),
            if (_preview != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: AppColors.caper, child: Text(_preview!.club.name.characters.first)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_preview!.club.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                            '${_preview!.club.category} · 구성원 ${_preview!.memberCount}명 · ${_preview!.club.joinPolicyLabel}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Text('찾았어요', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              MoaPrimaryButton(
                label: _preview!.club.requiresApproval ? '이 동아리에 가입 신청하기' : '이 동아리에 가입하기',
                busy: _busy,
                onPressed: _join,
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.line)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('또는', style: TextStyle(color: AppColors.bud))),
                Expanded(child: Divider(color: AppColors.line)),
              ],
            ),
            const SizedBox(height: 16),
            MoaOutlineButton(
              label: 'QR 코드 스캔하기',
              icon: Icons.qr_code_scanner,
              onPressed: () async {
                final value = await Navigator.pushNamed(context, AppRoutes.scan);
                if (value is String && value.isNotEmpty) await _lookup(value);
              },
            ),
            const SizedBox(height: 8),
            const Text(
              '초대 링크를 눌러 들어왔다면 코드가 자동으로 입력돼요',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: const Text('QR 코드 스캔하기')),
      body: MobileScanner(
        onDetect: (capture) {
          final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
          if (raw == null || raw.isEmpty) return;
          final match = RegExp(r'[A-Za-z0-9]{6}').firstMatch(raw);
          Navigator.pop(context, (match?.group(0) ?? raw).toUpperCase());
        },
      ),
    );
  }
}
