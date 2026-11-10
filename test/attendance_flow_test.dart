import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/theme/app_theme.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/models/accounting.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_router.dart';
import 'package:flutter_proj/router/app_routes.dart';
import 'package:flutter_proj/router/open_launch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('운영진은 모임 상세의 명단 보기로 출석 관리에 들어간다', (tester) async {
    final clubs = FakeAttendanceClubs();
    await _open(tester, clubs, AppRoutes.meetingDetail, _args('owner'));

    await tester.ensureVisible(find.text('명단 보기'));
    await tester.tap(find.text('명단 보기'));
    await tester.pumpAndSettle();

    expect(find.text('출석 관리'), findsOneWidget);
    expect(find.text('실시간 출석 현황'), findsOneWidget);
    expect(find.text('출석률 67% · 미출석 1명'), findsOneWidget);
    expect(find.text('방금 출석했어요'), findsOneWidget);

    await tester.tap(find.text('출석자 명단'));
    await tester.pumpAndSettle();
    expect(find.text('전체 3'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('운영진은 모임 상세의 QR 출석 코드 띄우기로 QR 화면에 들어간다', (tester) async {
    final clubs = FakeAttendanceClubs();
    await _open(tester, clubs, AppRoutes.meetingDetail, _args('owner'));

    await tester.tap(find.text('QR 출석 코드 띄우기'));
    await tester.pumpAndSettle();

    expect(find.text('QR 출석 코드'), findsOneWidget);
    expect(find.text('부원들에게 이 화면을 보여주세요'), findsOneWidget);
    expect(find.textContaining('남은 시간 0'), findsOneWidget);
    expect(find.text('2 / 3명 출석했어요'), findsOneWidget);
    expect(clubs.rotations, 1);
    expect(clubs.event.value.attendanceOpen, isTrue);

    await tester.tap(find.text('QR 새로 만들기'));
    await tester.pumpAndSettle();
    expect(clubs.rotations, 2);

    await tester.tap(find.text('출석 마감하기'));
    await tester.pumpAndSettle();
    expect(clubs.event.value.attendanceOpen, isFalse);
    expect(find.text('모임 상세'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('일반 부원은 읽기 전용 명단만 보고 QR 버튼이 없다', (tester) async {
    final clubs = FakeAttendanceClubs();
    await _open(tester, clubs, AppRoutes.meetingDetail, _args('member'));

    expect(find.text('QR 출석 코드 띄우기'), findsNothing);
    await tester.ensureVisible(find.text('명단 보기'));
    await tester.tap(find.text('명단 보기'));
    await tester.pumpAndSettle();

    expect(find.text('참석 명단'), findsOneWidget);
    expect(find.text('출석 관리'), findsNothing);
    await _close(tester);
  });

  testWidgets('출석자 명단에서 미출석자를 직접 출석 처리한다', (tester) async {
    final clubs = FakeAttendanceClubs();
    await _open(tester, clubs, AppRoutes.attendanceRoster, _args('owner'));

    expect(find.text('출석 2'), findsOneWidget);
    expect(find.text('미출석 1'), findsOneWidget);
    expect(find.text('아직 출석하지 않았어요'), findsOneWidget);

    await tester.tap(find.text('출석 처리'));
    await tester.pumpAndSettle();
    expect(find.text('정도윤님 출석 상태'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '휴대폰 배터리 방전');
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(clubs.manual.single.userId, 'doyun');
    expect(clubs.manual.single.reason, '휴대폰 배터리 방전');
    expect(clubs.manual.single.actorName, '백다혜');
    expect(find.text('출석 3'), findsOneWidget);
    expect(find.text('미출석 0'), findsOneWidget);
    expect(find.text('수동 출석'), findsOneWidget);
    expect(find.text('출석 처리'), findsNothing);
    await _close(tester);
  });

  testWidgets('미출석 유지를 고르면 출석 기록을 만들지 않는다', (tester) async {
    final clubs = FakeAttendanceClubs();
    await _open(tester, clubs, AppRoutes.attendanceRoster, _args('owner'));

    await tester.tap(find.text('출석 처리'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('미출석 유지'));
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(clubs.manual, isEmpty);
    expect(find.text('미출석 1'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('출석 탭은 다가오는 모임과 내 출석률, 최근 일정을 보여 준다', (tester) async {
    final clubs = FakeAttendanceClubs();
    await _open(tester, clubs, AppRoutes.attendance, const ClubArgs('club'));

    // 백다혜는 이 모임에 이미 출석한 상태입니다.
    expect(find.text('출석을 마쳤어요'), findsOneWidget);
    expect(find.text('2 / 3명'), findsOneWidget);
    expect(find.text('QR 스캔으로 출석하기'), findsOneWidget);
    expect(find.text('출석 관리'), findsOneWidget);
    expect(find.text('내 출석률 100%'), findsOneWidget);
    expect(find.text('이번 학기 모임 1회 중 1회 출석'), findsOneWidget);
    expect(find.textContaining(' QR 출석'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-attendance')), findsOneWidget);

    await tester.tap(find.text('구성원별 보기'));
    await tester.pumpAndSettle();
    expect(find.text('구성원별 출석률'), findsOneWidget);
    expect(find.text('이번 학기 평균 출석률'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('출석 완료 화면은 출석 시간과 내 출석률을 보여 준다', (tester) async {
    final clubs = FakeAttendanceClubs();
    final record = AttendanceRecord(
      userId: 'dahye',
      userName: '백다혜',
      method: AttendanceMethod.qr,
      checkedAt: DateTime(2026, 10, 31, 14, 3),
    );
    await _open(
      tester,
      clubs,
      AppRoutes.attendanceDone,
      AttendanceDoneArgs(
        result: CheckInResult(
          clubId: 'club',
          event: clubs.event.value,
          record: record,
          duplicate: false,
        ),
      ),
    );

    expect(find.text('출석 완료!'), findsOneWidget);
    expect(find.text('10.31 (토) 14:03'), findsOneWidget);
    expect(find.text('QR 스캔'), findsOneWidget);
    expect(find.text('100% (1회 중 1회)'), findsOneWidget);
    await _close(tester);
  });

  group('QR 스캔', () {
    late FakeScanner scanner;
    late FakeAttendanceClubs clubs;
    final qr = buildAttendanceQr(
      clubId: 'club',
      eventId: 'event',
      token: 'token',
    );

    setUp(() {
      scanner = FakeScanner();
      MobileScannerPlatform.instance = scanner;
      clubs = FakeAttendanceClubs();
    });

    CheckInResult result({required bool duplicate}) {
      return CheckInResult(
        clubId: 'club',
        event: clubs.event.value,
        record: AttendanceRecord(
          userId: 'dahye',
          userName: '백다혜',
          method: AttendanceMethod.qr,
          checkedAt: DateTime(2026, 10, 31, 14, 3),
        ),
        duplicate: duplicate,
      );
    }

    testWidgets('출석 QR을 찍으면 출석 완료 화면으로 넘어간다', (tester) async {
      clubs.onCheckIn = (_) async => result(duplicate: false);
      await _openScan(tester, clubs);
      expect(find.text('가을빛을 담는 연남 출사 · 오후 2:00'), findsOneWidget);

      scanner.scan(qr);
      await tester.pumpAndSettle();

      expect(clubs.scanned, [qr]);
      expect(find.text('출석 완료!'), findsOneWidget);
      expect(find.text('10.31 (토) 14:03'), findsOneWidget);
      await _close(tester);
    });

    testWidgets('이미 출석한 모임이면 안내 시트를 띄우고 스캔 화면을 닫는다', (tester) async {
      clubs.onCheckIn = (_) async => result(duplicate: true);
      await _openScan(tester, clubs);

      scanner.scan(qr);
      await tester.pumpAndSettle();

      expect(find.text('이미 출석했어요'), findsOneWidget);
      expect(find.text('다혜님은 10.31 14:03에 출석했어요.\n같은 모임에는 한 번만 출석할 수 있어요.'), findsOneWidget);
      expect(find.text('출석 완료!'), findsNothing);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.text('바탕 화면'), findsOneWidget);
      expect(find.text('로그인한 계정으로 자동 출석돼요'), findsNothing);
      await _close(tester);
    });

    testWidgets('출석 QR이 아니면 서버에 묻지 않고 안내만 한다', (tester) async {
      await _openScan(tester, clubs);

      scanner.scan('ABC123');
      await tester.pump();
      await tester.pump();

      expect(clubs.scanned, isEmpty);
      expect(find.text('모아 출석 QR이 아니에요.'), findsOneWidget);
      await _close(tester);
    });

    testWidgets('만료된 QR이면 이유를 알리고 잠시 뒤 다시 찍을 수 있다', (tester) async {
      clubs.onCheckIn = (_) async => throw StateError('QR이 만료되었어요.');
      await _openScan(tester, clubs);

      scanner.scan(qr);
      await tester.pump();
      await tester.pump();
      expect(find.text('QR이 만료되었어요.'), findsOneWidget);

      // 같은 QR이 계속 잡혀도 쉬는 동안에는 다시 요청하지 않습니다.
      scanner.scan(qr);
      await tester.pump();
      expect(clubs.scanned.length, 1);

      clubs.onCheckIn = (_) async => result(duplicate: false);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2100)),
      );
      scanner.scan(qr);
      await tester.pumpAndSettle();
      expect(clubs.scanned.length, 2);
      expect(find.text('출석 완료!'), findsOneWidget);
      await _close(tester);
    });
  });
}

Future<void> _openScan(WidgetTester tester, FakeAttendanceClubs clubs) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final deps = MoaDependencies(auth: FakeAttendanceAuth(), clubs: clubs);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(settings, deps),
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('바탕 화면')),
        ),
        AppRouter.onGenerateRoute(
          RouteSettings(name: AppRoutes.attendanceScan, arguments: _args('member')),
          deps,
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// 카메라 대신 테스트가 건네는 QR 내용을 스캔 결과로 흘려보냅니다.
class FakeScanner extends MobileScannerPlatform {
  final _barcodes = StreamController<BarcodeCapture?>.broadcast();

  void scan(String raw) {
    _barcodes.add(BarcodeCapture(barcodes: [Barcode(rawValue: raw)]));
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.expand();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(390, 478),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> dispose() async {}
}

MeetingArgs _args(String role) {
  return MeetingArgs(clubId: 'club', eventId: 'event', role: role);
}

Future<void> _open(
  WidgetTester tester,
  FakeAttendanceClubs clubs,
  String route,
  Object arguments,
) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final deps = MoaDependencies(auth: FakeAttendanceAuth(), clubs: clubs);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(settings, deps),
      onGenerateInitialRoutes: (_) => [
        AppRouter.onGenerateRoute(
          RouteSettings(name: route, arguments: arguments),
          deps,
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// QR 화면의 1초 타이머가 남지 않게 화면을 걷어 냅니다.
Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

class LiveValue<T> {
  LiveValue(this.value);

  T value;
  final _changes = StreamController<T>.broadcast();

  void set(T next) {
    value = next;
    _changes.add(next);
  }

  Stream<T> get stream async* {
    yield value;
    yield* _changes.stream;
  }
}

class ManualCall {
  const ManualCall(this.userId, this.actorName, this.reason);

  final String userId;
  final String actorName;
  final String? reason;
}

/// 참석 대상 세 명 중 두 명이 출석한 모임 하나를 가진 동아리입니다.
class FakeAttendanceClubs implements ClubGateway {
  FakeAttendanceClubs() {
    final start = kstNow().add(const Duration(days: 1));
    event = LiveValue(
      ClubEvent(
        id: 'event',
        badge: '정기 출사',
        title: '가을빛을 담는 연남 출사',
        schedule: '',
        artKicker: '',
        artTitle: '',
        imageUrl: _pixel,
        startsAt: DateTime(start.year, start.month, start.day, 14),
        place: '연트럴파크 입구',
        status: '예정',
        attendeeIds: const ['jiwoo', 'dahye', 'doyun'],
        attendeeInitials: const ['지', '다', '도'],
        attendeeSummary: '김지우, 백다혜, 정도윤 참석',
        checkedInCount: 2,
      ),
    );
    final at = kstNow();
    records = LiveValue([
      AttendanceRecord(
        userId: 'dahye',
        userName: '백다혜',
        method: AttendanceMethod.qr,
        checkedAt: at,
      ),
      AttendanceRecord(
        userId: 'jiwoo',
        userName: '김지우',
        method: AttendanceMethod.qr,
        checkedAt: at.subtract(const Duration(minutes: 8)),
      ),
    ]);
  }

  static const _pixel =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

  late final LiveValue<ClubEvent> event;
  late final LiveValue<List<AttendanceRecord>> records;
  final qr = LiveValue<QrSession?>(null);
  final manual = <ManualCall>[];
  final scanned = <String>[];
  int rotations = 0;

  /// QR 출석 요청에 돌려줄 결과입니다.
  Future<CheckInResult> Function(String raw)? onCheckIn;

  final user = const AppUser(
    id: 'dahye',
    name: '백다혜',
    email: 'dahye@moa.app',
    activityAlerts: false,
    nickname: '다혜',
  );

  final club = const Club(
    id: 'club',
    name: '픽쳐 사진동아리',
    tagline: '사진으로 연결되는 우리',
    category: '동아리',
    joinPolicy: 'open',
    imageUrl: _pixel,
    ownerId: 'dahye',
    ownerName: '백다혜',
    memberCount: 3,
    balance: 0,
    duesPaidCount: 0,
    duesTotalCount: 0,
    duesMonthLabel: '',
  );

  static const members = [
    ClubMember(userId: 'dahye', userName: '백다혜', role: 'owner', status: 'active'),
    ClubMember(userId: 'jiwoo', userName: '김지우', role: 'member', status: 'active'),
    ClubMember(userId: 'doyun', userName: '정도윤', role: 'member', status: 'active'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<AppUser?> getUser(String uid) async => user;

  @override
  Future<ClubEvent> loadEvent({
    required String clubId,
    required String eventId,
  }) async => event.value;

  @override
  Future<List<ClubEvent>> loadMeetings({required String clubId}) async => [
    event.value,
  ];

  @override
  Future<ClubDesk> loadDesk({
    required String uid,
    required String clubId,
  }) async {
    return ClubDesk(
      user: user,
      club: club,
      myRole: 'owner',
      members: members,
      requests: const [],
    );
  }

  @override
  Future<HomeData> loadHome({
    required String uid,
    required String clubId,
  }) async {
    return HomeData(
      user: user,
      club: club,
      clubs: [club],
      events: [event.value],
      activities: const [],
      notices: const [],
      tasks: const [],
      role: 'owner',
      options: const [],
    );
  }

  @override
  Future<void> markNoticesRead(String clubId) async {}

  @override
  Stream<ClubEvent> watchEvent({
    required String clubId,
    required String eventId,
  }) => event.stream;

  @override
  Stream<List<AttendanceRecord>> watchAttendance({
    required String clubId,
    required String eventId,
  }) => records.stream;

  @override
  Future<Map<String, List<AttendanceRecord>>> loadAttendanceRecords({
    required String clubId,
    required List<String> eventIds,
  }) async => {for (final id in eventIds) id: records.value};

  @override
  Stream<QrSession?> watchAttendanceQr({
    required String clubId,
    required String eventId,
  }) => qr.stream;

  @override
  Future<QrSession> rotateAttendanceQr({
    required String clubId,
    required String eventId,
  }) async {
    rotations++;
    final session = QrSession(
      token: 'token$rotations',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    qr.set(session);
    _setOpen(true);
    return session;
  }

  @override
  Future<void> closeAttendance({
    required String clubId,
    required String eventId,
  }) async {
    qr.set(null);
    _setOpen(false);
  }

  @override
  Future<CheckInResult> checkInWithQr({
    required String uid,
    required String raw,
  }) {
    scanned.add(raw);
    return onCheckIn!(raw);
  }

  @override
  Future<void> markAttendanceManually({
    required String clubId,
    required String eventId,
    required String userId,
    required String userName,
    required String actorId,
    required String actorName,
    String? reason,
  }) async {
    manual.add(ManualCall(userId, actorName, reason));
    records.set([
      AttendanceRecord(
        userId: userId,
        userName: userName,
        method: AttendanceMethod.manual,
        checkedAt: kstNow(),
        reason: reason,
        actorId: actorId,
        actorName: actorName,
      ),
      ...records.value,
    ]);
  }

  @override
  Future<AccountingData> loadAccounting({
    required String uid,
    required String clubId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> registerDues({
    required String clubId,
    required String actorId,
    required String title,
    required int amount,
    required DateTime dueAt,
    required String repeat,
    required bool allMembers,
    required List<DuesTarget> targets,
  }) async {}

  @override
  Future<void> reportDuesPayment({
    required String clubId,
    required String duesId,
    required String userId,
    required String depositName,
  }) async {}

  @override
  Future<void> confirmDuesPayment({
    required String clubId,
    required String duesId,
    required String userId,
    required String actorId,
    required String actorName,
    required String ledgerTitle,
    required int amount,
  }) async {}

  @override
  Future<void> remindUnpaidDues({
    required String clubId,
    required String actorId,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> saveLedgerEntry({
    required String clubId,
    required String actorId,
    required String actorName,
    String? entryId,
    required String kind,
    required int amount,
    required String title,
    required DateTime occurredAt,
    required String category,
    required String memo,
    ImagePayload? receipt,
  }) async {}

  @override
  Future<void> deleteLedgerEntry({
    required String clubId,
    required String entryId,
  }) async {}

  void _setOpen(bool open) {
    final now = event.value;
    event.set(
      ClubEvent(
        id: now.id,
        badge: now.badge,
        title: now.title,
        schedule: now.schedule,
        artKicker: now.artKicker,
        artTitle: now.artTitle,
        imageUrl: now.imageUrl,
        attendanceOpen: open,
        attendeeInitials: now.attendeeInitials,
        attendeeSummary: now.attendeeSummary,
        startsAt: now.startsAt,
        place: now.place,
        status: now.status,
        attendeeIds: now.attendeeIds,
        checkedInCount: now.checkedInCount,
      ),
    );
  }
}

class FakeAttendanceAuth implements AuthGateway {
  @override
  String? get currentUid => 'dahye';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
