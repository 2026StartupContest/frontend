import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';

/// 앱을 시작할 때 동아리 정보를 불러오지 못하면(오프라인 등) 보여 주는 화면입니다(#20).
/// 다시 시도하면 원래 시작 화면으로 이동합니다.
class LaunchRetryScreen extends StatefulWidget {
  const LaunchRetryScreen({super.key, required this.deps});

  final MoaDependencies deps;

  @override
  State<LaunchRetryScreen> createState() => _LaunchRetryScreenState();
}

class _LaunchRetryScreenState extends State<LaunchRetryScreen> {
  String _message = '네트워크 연결을 확인해 주세요.';
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await openLaunch(context, widget.deps);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = friendlyErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _busy
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : MoaErrorState(message: _message, onRetry: _retry),
    );
  }
}
