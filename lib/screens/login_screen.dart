import 'package:flutter/material.dart';
import 'package:flutter_proj/core/auth_error_message.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/view_models/base_view_model.dart';
import 'package:flutter_proj/widgets/moa_widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginViewModel extends BaseViewModel {
  LoginViewModel(this.auth);

  final AuthGateway auth;

  Future<bool> submit(String email, String password) async {
    setError(null);
    setLoading(true);
    try {
      await auth.signInWithEmail(email: email, password: password);
      return true;
    } catch (error) {
      setError(error);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> google() async {
    setError(null);
    setLoading(true);
    try {
      await auth.signInWithGoogle();
      return true;
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled) setError(error);
      return false;
    } catch (error) {
      setError(error);
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<String?> reset(String email) async {
    setError(null);
    try {
      await auth.sendPasswordReset(email);
      return '비밀번호 재설정 메일을 보냈어요.';
    } catch (error) {
      setError(error);
      return null;
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.deps});

  final MoaDependencies deps;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginViewModel _model;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = LoginViewModel(widget.deps.auth);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _afterAuth() async {
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    await widget.deps.clubs.ensureUser(
      id: uid,
      name: widget.deps.auth.currentDisplayName ?? '',
      email: widget.deps.auth.currentEmail ?? _email.text,
    );
    if (!mounted) return;
    await openLaunch(context, widget.deps);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _model,
          builder: (context, _) {
            final message = _model.error == null ? null : authErrorMessage(_model.error!);
            return ListView(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
              children: [
                const MoaLogo(),
                const SizedBox(height: 36),
                const Text(
                  '함께하는 모임,\n가벼워진 운영.',
                  style: TextStyle(fontSize: 27, height: 1.35, fontWeight: FontWeight.w800, letterSpacing: -1.2),
                ),
                const SizedBox(height: 12),
                const Text(
                  '회비부터 출석, 정산까지\n우리 동아리의 모든 순간을 한곳에서.',
                  style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
                ),
                const SizedBox(height: 28),
                MoaField(label: '이메일', controller: _email, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                MoaField(label: '비밀번호', controller: _password, obscure: true),
                const SizedBox(height: 18),
                MoaPrimaryButton(
                  label: '로그인',
                  busy: _model.isLoading,
                  onPressed: () async {
                    final ok = await _model.submit(_email.text, _password.text);
                    if (ok) await _afterAuth();
                  },
                ),
                if (message != null && message.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(message, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final note = await _model.reset(_email.text);
                        if (!context.mounted || note == null) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(note)));
                      },
                      child: const Text('비밀번호 찾기', style: TextStyle(color: AppColors.label, fontSize: 13)),
                    ),
                    const Text('|', style: TextStyle(color: AppColors.bud)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.signup,
                        arguments: SignupMode.create,
                      ),
                      child: const Text('회원가입', style: TextStyle(color: AppColors.label, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.line)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('간편 로그인', style: TextStyle(fontSize: 12, color: AppColors.bud)),
                    ),
                    Expanded(child: Divider(color: AppColors.line)),
                  ],
                ),
                const SizedBox(height: 16),
                MoaOutlineButton(
                  label: '구글로 시작하기',
                  icon: Icons.g_mobiledata,
                  onPressed: _model.isLoading
                      ? null
                      : () async {
                          final ok = await _model.google();
                          if (ok) await _afterAuth();
                        },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
