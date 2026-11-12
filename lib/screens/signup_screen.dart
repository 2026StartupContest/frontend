import 'package:flutter/material.dart';
import 'package:flutter_proj/core/auth_error_message.dart';
import 'package:flutter_proj/core/auth_validators.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/view_models/base_view_model.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';

class SignupViewModel extends BaseViewModel {
  bool terms = false;
  bool privacy = false;
  bool alerts = false;

  bool get allChecked => terms && privacy && alerts;

  void toggleAll(bool value) {
    terms = value;
    privacy = value;
    alerts = value;
    notifyListeners();
  }

  void setTerms(bool value) {
    terms = value;
    notifyListeners();
  }

  void setPrivacy(bool value) {
    privacy = value;
    notifyListeners();
  }

  void setAlerts(bool value) {
    alerts = value;
    notifyListeners();
  }

  void busy(bool value) => setLoading(value);
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.deps, required this.mode});

  final MoaDependencies deps;
  final SignupMode mode;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _model = SignupViewModel();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _message;

  bool get _needsPassword => widget.mode == SignupMode.create;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.deps.auth.currentDisplayName ?? '');
    _email = TextEditingController(text: widget.deps.auth.currentEmail ?? '');
    _password.addListener(_refresh);
    _confirm.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _model.dispose();
    _password.removeListener(_refresh);
    _confirm.removeListener(_refresh);
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ready = AuthValidators.canSubmitSignup(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      confirm: _confirm.text,
      termsAccepted: _model.terms,
      privacyAccepted: _model.privacy,
      needsPassword: _needsPassword,
    );
    if (!ready) {
      setState(() => _message = '이름, 이메일, 비밀번호와 필수 약관을 확인해 주세요.');
      return;
    }
    setState(() => _message = null);
    _model.busy(true);
    try {
      if (_needsPassword) {
        await widget.deps.auth.signUpWithEmail(
          email: _email.text,
          password: _password.text,
          name: _name.text,
        );
      }
      final uid = widget.deps.auth.currentUid;
      if (uid == null) throw StateError('계정을 만들지 못했어요.');
      await widget.deps.clubs.ensureUser(
        id: uid,
        name: _name.text,
        email: _email.text,
        activityAlerts: _model.alerts,
      );
      if (!mounted) return;
      if (_needsPassword) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.signupDone,
          arguments: SignupDoneArgs(name: _name.text.trim(), email: _email.text.trim()),
        );
      } else {
        await openLaunch(context, widget.deps);
      }
    } catch (error) {
      if (mounted) setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) _model.busy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordOk = AuthValidators.isPasswordValid(_password.text);
    final matches = AuthValidators.passwordsMatch(_password.text, _confirm.text);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _model,
          builder: (context, _) {
            return Column(
              children: [
                const MoaPageHeader(title: '회원가입'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      const MoaStepper(active: 1),
                      const SizedBox(height: 22),
                      const Text(
                        '반가워요!\n기본 정보를 알려주세요',
                        style: TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const Text('동아리 구성원에게 보일 이름이에요.', style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 22),
                      MoaField(label: '이름', controller: _name),
                      const SizedBox(height: 16),
                      MoaField(
                        label: '이메일',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (_needsPassword) ...[
                        const SizedBox(height: 16),
                        MoaField(
                          label: '비밀번호',
                          controller: _password,
                          obscure: true,
                          helper: '영문·숫자 포함 8자 이상',
                          helperColor: passwordOk ? AppColors.primary : AppColors.muted,
                        ),
                        const SizedBox(height: 16),
                        MoaField(
                          label: '비밀번호 확인',
                          controller: _confirm,
                          obscure: true,
                          helper: _confirm.text.isEmpty
                              ? null
                              : matches
                              ? '비밀번호가 일치해요'
                              : '비밀번호가 달라요',
                          helperColor: matches ? AppColors.primary : AppColors.danger,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _checks(),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(_message!, style: const TextStyle(color: AppColors.danger)),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: MoaPrimaryButton(
                    label: _needsPassword ? '가입하기' : '시작하기',
                    busy: _model.isLoading,
                    onPressed: _submit,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _checks() {
    return Material(
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            CheckboxListTile(
              value: _model.allChecked,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('약관 전체 동의', style: TextStyle(fontWeight: FontWeight.w700)),
              onChanged: (value) => _model.toggleAll(value ?? false),
            ),
            _row('필수', '서비스 이용약관', _model.terms, _model.setTerms, _termsBody),
            _row('필수', '개인정보 처리방침', _model.privacy, _model.setPrivacy, _privacyBody),
            CheckboxListTile(
              value: _model.alerts,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('[선택] 활동 알림 받기', style: TextStyle(fontSize: 14)),
              onChanged: (value) => _model.setAlerts(value ?? false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String badge, String label, bool value, ValueChanged<bool> onChanged, String body) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (next) => onChanged(next ?? false)),
        Expanded(child: Text('[$badge] $label', style: const TextStyle(fontSize: 14))),
        TextButton(
          onPressed: () => showMoaSheet(context, title: label, body: body),
          child: const Text('보기', style: TextStyle(color: AppColors.label)),
        ),
      ],
    );
  }
}

const _termsBody = '모해 서비스는 동아리의 회비, 출석, 정산 기록을 구성원과 함께 보기 위한 도구입니다. 허위 정보나 다른 사람의 계정을 사용하면 이용이 제한될 수 있습니다.';
const _privacyBody = '이름과 이메일은 동아리 구성원에게 표시되고, 가입 신청과 회비 확인에 사용됩니다. 비밀번호는 Firebase Authentication이 관리하며 앱에 저장하지 않습니다.';
