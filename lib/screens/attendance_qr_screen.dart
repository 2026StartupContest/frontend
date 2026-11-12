import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_proj/view_models/meeting_attendance_feed.dart';
import 'package:flutter_proj/widgets/attendance_widgets.dart';
import 'package:flutter_proj/widgets/club_chrome.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AttendanceQrScreen extends StatefulWidget {
  const AttendanceQrScreen({super.key, required this.deps, required this.args});

  final MoaDependencies deps;
  final MeetingArgs args;

  @override
  State<AttendanceQrScreen> createState() => _AttendanceQrScreenState();
}

class _AttendanceQrScreenState extends State<AttendanceQrScreen> {
  late final MeetingAttendanceFeed _feed = MeetingAttendanceFeed(
    clubs: widget.deps.clubs,
    clubId: widget.args.clubId,
    eventId: widget.args.eventId!,
  );
  StreamSubscription<QrSession?>? _qrSub;
  Timer? _ticker;
  QrSession? _session;
  bool _listening = false;
  bool _rotating = false;
  bool _closing = false;
  String? _message;

  String get _clubId => widget.args.clubId;
  String get _eventId => widget.args.eventId!;

  @override
  void initState() {
    super.initState();
    _qrSub = widget.deps.clubs
        .watchAttendanceQr(clubId: _clubId, eventId: _eventId)
        .listen(
          (session) {
            if (!mounted) return;
            setState(() {
              _session = session;
              _listening = true;
            });
            _keepFresh();
          },
          onError: (Object error) {
            if (mounted) setState(() => _message = attendanceErrorText(error));
          },
        );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _keepFresh();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _qrSub?.cancel();
    _feed.dispose();
    super.dispose();
  }

  /// 유효한 QR이 없으면 새로 만듭니다. 한 번 실패하면 버튼으로만 다시 시도합니다.
  void _keepFresh() {
    if (!_listening || _rotating || _closing || _message != null) return;
    final session = _session;
    if (session == null || session.isExpired(DateTime.now())) _rotate();
  }

  Future<void> _rotate() async {
    if (_rotating || _closing) return;
    setState(() {
      _rotating = true;
      _message = null;
    });
    try {
      final session = await widget.deps.clubs.rotateAttendanceQr(
        clubId: _clubId,
        eventId: _eventId,
      );
      if (mounted) setState(() => _session = session);
    } catch (error) {
      if (mounted) setState(() => _message = attendanceErrorText(error));
    } finally {
      if (mounted) setState(() => _rotating = false);
    }
  }

  Future<void> _close() async {
    if (_closing) return;
    setState(() => _closing = true);
    try {
      await widget.deps.clubs.closeAttendance(
        clubId: _clubId,
        eventId: _eventId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('출석을 마감했어요.')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _closing = false);
      await showMoaError(context, StateError(attendanceErrorText(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AttendanceAppBar(title: 'QR 출석 코드'),
            Expanded(
              child: ListenableBuilder(
                listenable: _feed,
                builder: (context, _) {
                  final event = _feed.event;
                  if (event == null) {
                    return Center(
                      child: _feed.message == null
                          ? const CircularProgressIndicator(
                              color: AppColors.primary,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _feed.message!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 11.5, 24, 41),
                    children: [
                      const Text(
                        '부원들에게 이 화면을 보여주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.8,
                          letterSpacing: -0.4,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _qrCard(event),
                      const SizedBox(height: 12),
                      _LiveCard(feed: _feed, event: event),
                    ],
                  );
                },
              ),
            ),
            AttendanceBottomBar(
              children: [
                AttendanceButton(
                  label: 'QR 새로 만들기',
                  icon: 'refresh',
                  iconSize: 16,
                  tone: AttendanceButtonTone.outline,
                  onPressed: _rotating || _closing ? null : _rotate,
                ),
                AttendanceButton(
                  label: '출석 마감하기',
                  busy: _closing,
                  onPressed: _close,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrCard(ClubEvent event) {
    final session = _session;
    final now = DateTime.now();
    final live = session != null && !session.isExpired(now);
    return AttendanceCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(19.6, 21.6, 19.6, 17.6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.peach,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AttendanceIcon('clock'),
                const SizedBox(width: 6),
                Text(
                  '남은 시간 ${formatCountdown(live ? session.remaining(now) : Duration.zero)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.copper,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 7.8),
            child: SizedBox.square(
              dimension: 220,
              child: live
                  ? QrImageView(
                      key: ValueKey(session.token),
                      data: buildAttendanceQr(
                        clubId: _clubId,
                        eventId: _eventId,
                        token: session.token,
                      ),
                      size: 220,
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.ink,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.ink,
                      ),
                    )
                  : Center(
                      child: _message == null
                          ? const CircularProgressIndicator(
                              color: AppColors.primary,
                            )
                          : Text(
                              'QR을 만들지 못했어요.\n$_message',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color: AppColors.danger,
                              ),
                            ),
                    ),
            ),
          ),
          Text(
            event.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'QR은 5분마다 새로 바뀌어서 캡처해 보내도 출석할 수 없어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.8,
              letterSpacing: -0.4,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.feed, required this.event});

  final MeetingAttendanceFeed feed;
  final ClubEvent event;

  @override
  Widget build(BuildContext context) {
    final recent = feed.records.take(4).toList();
    return AttendanceCard(
      padding: const EdgeInsets.fromLTRB(19.6, 20.6, 19.6, 19.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${feed.checked} / ${feed.total}명 출석했어요',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const LiveCaption('실시간'),
            ],
          ),
          const SizedBox(height: 4),
          AttendanceProgress(value: feed.progress),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            child: Row(
              children: [
                AttendanceAvatarStack(
                  avatars: [
                    for (final record in recent)
                      (record.initial, attendeeColor(event, record.userId)),
                  ],
                ),
                if (recent.isNotEmpty) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recent.isEmpty
                        ? '아직 출석한 사람이 없어요'
                        : '방금 ${recent.first.userName}님이 출석했어요',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: -0.4,
                      color: Color(0xFF75816F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
