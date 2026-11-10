import 'package:flutter/material.dart';
import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/core/format.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/view_models/meeting_attendance_feed.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// 운영진이 띄운 출석 QR을 찍는 화면입니다.
/// [MeetingArgs.eventId]가 있으면 어떤 모임인지 아래 칩으로 보여 줍니다.
class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({
    super.key,
    required this.deps,
    required this.args,
  });

  final MoaDependencies deps;
  final MeetingArgs args;

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  static const _retryGap = Duration(seconds: 2);

  final _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  ClubEvent? _event;
  String? _nickname;

  /// 출석 요청을 보낸 뒤로는 새 스캔을 받지 않습니다.
  bool _busy = false;

  /// 서버 응답을 기다리는 동안만 안내선 자리에 로딩을 보여 줍니다.
  bool _checking = false;
  DateTime _quietUntil = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final uid = widget.deps.auth.currentUid;
    final eventId = widget.args.eventId;
    try {
      if (eventId != null) {
        final event = await widget.deps.clubs.loadEvent(
          clubId: widget.args.clubId,
          eventId: eventId,
        );
        if (mounted) setState(() => _event = event);
      }
      if (uid != null) {
        final user = await widget.deps.clubs.getUser(uid);
        if (mounted) setState(() => _nickname = user?.displayNickname);
      }
    } catch (_) {
      // 칩과 닉네임은 안내용이라 못 불러와도 스캔은 그대로 할 수 있습니다.
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || DateTime.now().isBefore(_quietUntil)) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;
    final uid = widget.deps.auth.currentUid;
    if (uid == null) return;
    if (parseAttendanceQr(raw) == null) {
      _fail('모아 출석 QR이 아니에요.');
      return;
    }
    setState(() {
      _busy = true;
      _checking = true;
    });
    try {
      final result = await widget.deps.clubs.checkInWithQr(uid: uid, raw: raw);
      if (!mounted) return;
      if (result.duplicate) {
        // 시트가 떠 있는 동안에도 새 스캔은 계속 막아 둡니다.
        setState(() => _checking = false);
        await _showDuplicate(result);
        if (mounted) Navigator.pop(context);
        return;
      }
      await Navigator.pushReplacementNamed(
        context,
        AppRoutes.attendanceDone,
        arguments: AttendanceDoneArgs(result: result, role: widget.args.role),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _checking = false;
      });
      _fail(attendanceErrorText(error));
    }
  }

  /// 같은 QR이 계속 잡혀도 안내가 연달아 뜨지 않게 잠깐 쉽니다.
  void _fail(String message) {
    _quietUntil = DateTime.now().add(_retryGap);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: _retryGap));
  }

  Future<void> _showDuplicate(CheckInResult result) {
    final nickname = _nickname?.trim() ?? '';
    return showDuplicateAttendanceSheet(
      context,
      name: nickname.isEmpty ? result.record.userName : nickname,
      checkedAt: result.record.checkedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    return Scaffold(
      backgroundColor: AppColors.scanBg,
      body: SafeArea(
        child: Column(
          children: [
            AttendanceAppBar(
              title: 'QR 출석',
              dark: true,
              trailing: AttendanceIconButton(
                icon: 'flash',
                label: '플래시',
                onPressed: _scanner.toggleTorch,
              ),
            ),
            // 화면이 작으면 줄어들고, 커도 디자인 높이보다 커지지 않습니다.
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 478),
                  child: _ScanView(
                    scanner: _scanner,
                    onDetect: _onDetect,
                    busy: _checking,
                  ),
                ),
              ),
            ),
            if (event != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AttendanceIcon('calendar'),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        event.startsAt == null
                            ? event.title
                            : '${event.title} · ${formatClock(event.startsAt!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          letterSpacing: -0.4,
                          color: Color(0xFFDFE9E0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: Text(
                '로그인한 계정으로 자동 출석돼요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.8,
                  letterSpacing: -0.4,
                  color: Color(0xFF9FB0A3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 이미 출석한 모임의 QR을 다시 찍었을 때 띄우는 안내입니다.
Future<void> showDuplicateAttendanceSheet(
  BuildContext context, {
  required String name,
  required DateTime checkedAt,
}) {
  return showAttendanceSheet<void>(
    context,
    builder: (context) => Column(
      children: [
        const SizedBox(height: 20),
        AttendanceStatusHero(
          icon: 'warning',
          iconBackground: AppColors.peach,
          title: '이미 출석했어요',
          topPadding: 6,
          lines: [
            '$name님은 ${formatNoticeTime(checkedAt)}에 출석했어요.',
            '같은 모임에는 한 번만 출석할 수 있어요.',
          ],
        ),
        const SizedBox(height: 20),
        AttendanceButton(
          label: '확인',
          height: 48,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

class _ScanView extends StatelessWidget {
  const _ScanView({
    required this.scanner,
    required this.onDetect,
    required this.busy,
  });

  final MobileScannerController scanner;
  final void Function(BarcodeCapture) onDetect;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 카메라가 켜지기 전이나 권한이 없을 때 보이는 바탕입니다.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.45, -1),
                end: Alignment(0.45, 1),
                colors: [
                  Color(0xFF34413A),
                  Color(0xFF1D2620),
                  Color(0xFF2A332D),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          const Positioned(
            left: -60,
            top: -40,
            child: _Blob(size: 220, color: Color(0x595B7A62)),
          ),
          const Positioned(
            right: -50,
            bottom: 48,
            child: _Blob(size: 180, color: Color(0x593F5A69)),
          ),
          MobileScanner(
            controller: scanner,
            onDetect: onDetect,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => const SizedBox.shrink(),
            errorBuilder: (context, error) => const Align(
              alignment: Alignment(0, -0.8),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '카메라를 쓸 수 없어요. 설정에서 카메라 권한을 허용해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFFE7EFE8)),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.153),
            child: SizedBox.square(
              dimension: 230,
              child: busy
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.scanGuide,
                      ),
                    )
                  : const _ScanFrame(),
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 50.8,
            child: Text(
              '운영진 화면의 QR 코드를\n네모 칸 안에 맞춰 주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                letterSpacing: -0.4,
                color: Color(0xFFE7EFE8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: SizedBox.square(dimension: size),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final corner in const [
          Alignment.topLeft,
          Alignment.topRight,
          Alignment.bottomLeft,
          Alignment.bottomRight,
        ])
          Align(alignment: corner, child: _Corner(corner: corner)),
        Positioned(
          left: 18,
          right: 18,
          top: 105.8,
          child: Container(
            height: 2,
            decoration: const BoxDecoration(
              color: AppColors.scanGuide,
              boxShadow: [
                BoxShadow(color: AppColors.scanGuide, blurRadius: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 둥근 사각형 테두리를 그리고 한쪽 모서리 44px만 잘라 보여 줍니다.
class _Corner extends StatelessWidget {
  const _Corner({required this.corner});

  final Alignment corner;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox.square(
        dimension: 44,
        child: OverflowBox(
          alignment: corner,
          minWidth: 88,
          maxWidth: 88,
          minHeight: 88,
          maxHeight: 88,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.scanGuide, width: 3.81),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
