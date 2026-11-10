import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_proj/core/auth_error_message.dart';
import 'package:flutter_proj/data/place_dummy.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:flutter_proj/widgets/club_sheets.dart';
import 'package:flutter_proj/widgets/moa_bottom_nav.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key, required this.deps, required this.clubId});

  final MoaDependencies deps;
  final String clubId;

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final _nickname = TextEditingController();
  final _nicknameFocus = FocusNode();
  ProfileData? _profile;
  String? _message;
  bool _busy = false;
  bool? _alerts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nickname.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      final profile = await widget.deps.clubs.loadProfile(uid);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _alerts = profile.user.activityAlerts;
        _message = null;
        if (!_nicknameFocus.hasFocus) {
          _nickname.text = profile.user.displayNickname;
        }
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    }
  }

  void _goHome() {
    var foundHome = false;
    Navigator.popUntil(context, (route) {
      final isHome = route.settings.name == AppRoutes.home;
      if (isHome) foundHome = true;
      return isHome || route.isFirst;
    });
    if (!foundHome && mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.home,
        arguments: HomeArgs(widget.clubId),
      );
    }
  }

  Future<void> _saveNickname() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.deps.clubs.updateNickname(
        uid: uid,
        nickname: _nickname.text,
      );
      if (!mounted) return;
      _nicknameFocus.unfocus();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('닉네임을 저장했어요.')));
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _makePrimary(ClubOption option) async {
    if (option.primary || _busy) return;
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    try {
      await widget.deps.clubs.setPrimaryClub(uid: uid, clubId: option.club.id);
      await _load();
    } catch (error) {
      if (mounted) await showMoaError(context, error);
    }
  }

  Future<void> _setAlerts(bool value) async {
    final uid = widget.deps.auth.currentUid;
    final previous = _alerts ?? false;
    if (uid == null || _busy) return;
    setState(() => _alerts = value);
    try {
      await widget.deps.clubs.updateActivityAlerts(uid: uid, enabled: value);
    } catch (error) {
      if (!mounted) return;
      setState(() => _alerts = previous);
      await showMoaError(context, error);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _profile?.user.email.trim() ?? '';
    if (email.isEmpty) {
      await showMoaError(context, StateError('등록된 이메일이 없어요.'));
      return;
    }
    try {
      await widget.deps.auth.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('비밀번호 재설정 메일을 보냈어요.')));
    } catch (error) {
      if (!mounted) return;
      await _showFailure(error);
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    await widget.deps.auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  Future<void> _withdraw() async {
    final profile = _profile;
    final uid = widget.deps.auth.currentUid;
    if (profile == null || uid == null || _busy) return;
    final confirmed = await showLeaveAccountSheet(
      context,
      ownedLine: profile.ownedLine,
      joinedLine: profile.joinedLine,
    );
    if (!confirmed || !mounted) return;
    if (profile.ownedClubs.isNotEmpty) {
      await showMoaError(context, StateError('먼저 회장을 넘겨야 해요.'));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.deps.auth.ensureRecentLogin();
      await widget.deps.clubs.deleteAccountData(uid);
      await widget.deps.auth.deleteAccount();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (error) {
      if (mounted) await _showFailure(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showFailure(Object error) async {
    if (error is FirebaseAuthException) {
      final message = authErrorMessage(error);
      if (message.isEmpty) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    await showMoaError(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppBar(onBack: _goHome),
            Expanded(
              child: profile == null
                  ? Center(
                      child: _message == null
                          ? const CircularProgressIndicator(
                              color: AppColors.primary,
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Text(
                                _message!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 17, 24, 120),
                      children: [
                        _ProfileCard(
                          user: profile.user,
                          onEdit: () => _nicknameFocus.requestFocus(),
                        ),
                        const _Label('닉네임', top: 8),
                        const SizedBox(height: 9),
                        _NicknameRow(
                          controller: _nickname,
                          focusNode: _nicknameFocus,
                          onSave: _saveNickname,
                        ),
                        const _Label('내 동아리'),
                        const SizedBox(height: 9),
                        _ClubCard(
                          clubs: profile.visibleClubs,
                          onPrimary: _makePrimary,
                        ),
                        const _Label('설정'),
                        const SizedBox(height: 9),
                        _SettingsCard(
                          alerts: _alerts ?? profile.user.activityAlerts,
                          onAlerts: _setAlerts,
                          onPassword: _sendPasswordReset,
                        ),
                        const SizedBox(height: 10),
                        _LogoutButton(onPressed: _busy ? null : _signOut),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: _busy ? null : _withdraw,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.muted,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              '회원 탈퇴',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.4,
                                color: AppColors.muted,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MoaBottomNav(
        selected: MoaTab.myPage,
        onSelected: (tab) {
          if (tab == MoaTab.home) _goHome();
          if (tab == MoaTab.attendance) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.attendance,
              arguments: ClubArgs(widget.clubId),
            );
          }
          if (tab == MoaTab.reservation) {
            Navigator.pushNamed(
              context,
              AppRoutes.places,
              arguments: PlaceFlowArgs(clubId: widget.clubId),
            );
          }
        },
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: const Icon(
                  Icons.chevron_left,
                  size: 28,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Expanded(
              child: Text(
                '마이페이지',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.onEdit});

  final AppUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = user.name.trim().isEmpty ? user.displayNickname : user.name;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFD9E3CB),
              shape: BoxShape.circle,
            ),
            child: Text(
              user.initial,
              style: const TextStyle(
                fontSize: 22,
                color: Color(0xFF53634A),
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: -0.4,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.soft,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: const SizedBox(
                width: 42,
                height: 38,
                child: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NicknameRow extends StatelessWidget {
  const _NicknameRow({
    required this.controller,
    required this.focusNode,
    required this.onSave,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 13, color: AppColors.ink),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: _inputBorder(),
              focusedBorder: _inputBorder(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onSave,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.soft,
            foregroundColor: AppColors.primary,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '저장',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _inputBorder([Color color = AppColors.line]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: BorderSide(color: color),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.clubs, required this.onPrimary});

  final List<ClubOption> clubs;
  final ValueChanged<ClubOption> onPrimary;

  @override
  Widget build(BuildContext context) {
    if (clubs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: _cardDecoration(),
        child: const Text(
          '가입한 동아리가 없어요',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var index = 0; index < clubs.length; index++)
            _ClubRow(
              option: clubs[index],
              bordered: index != clubs.length - 1,
              onPrimary: () => onPrimary(clubs[index]),
            ),
        ],
      ),
    );
  }
}

class _ClubRow extends StatelessWidget {
  const _ClubRow({
    required this.option,
    required this.bordered,
    required this.onPrimary,
  });

  final ClubOption option;
  final bool bordered;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final role = ClubAccess.label(option.role);
    final subtitle = option.primary ? '$role · 대표 동아리' : role;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: bordered
            ? const Border(
                bottom: BorderSide(color: AppColors.chip, width: 0.6),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.club.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: -0.4,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onPrimary,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(
              option.primary ? Icons.star_rounded : Icons.star_border_rounded,
              size: 18,
              color: option.primary
                  ? const Color(0xFFD9A441)
                  : const Color(0xFF9BA499),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.alerts,
    required this.onAlerts,
    required this.onPassword,
  });

  final bool alerts;
  final ValueChanged<bool> onAlerts;
  final VoidCallback onPassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _SettingsRow(
            title: '알림 받기',
            subtitle: '모임 · 출석 · 회비 · 정산',
            bordered: true,
            trailing: _AlertSwitch(value: alerts, onChanged: onAlerts),
          ),
          _SettingsRow(
            title: '비밀번호 변경',
            bordered: true,
            onTap: onPassword,
            trailing: const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.bud,
            ),
          ),
          const _SettingsRow(
            title: '앱 정보',
            subtitle: '버전 1.0.0',
            trailing: Icon(Icons.chevron_right, size: 18, color: AppColors.bud),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.trailing,
    this.subtitle,
    this.bordered = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool bordered;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: bordered
              ? const Border(
                  bottom: BorderSide(color: AppColors.chip, width: 0.6),
                )
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      color: AppColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: -0.4,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _AlertSwitch extends StatelessWidget {
  const _AlertSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      label: '알림 받기',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 26,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? AppColors.primary : const Color(0xFFC7CEC0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 160),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.white,
        side: const BorderSide(color: Color(0xFFD9E1D1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, size: 16),
          SizedBox(width: 6),
          Text(
            '로그아웃',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(19),
    border: Border.all(color: AppColors.chip),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.top = 14});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
