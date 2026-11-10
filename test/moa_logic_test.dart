import 'dart:math';

import 'package:flutter_proj/core/accounting.dart';
import 'package:flutter_proj/core/settlement.dart';
import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/core/auth_validators.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/meeting_filter.dart';
import 'package:flutter_proj/core/session_destination.dart';
import 'package:flutter_proj/data/services/club_service.dart';
import 'package:flutter_proj/models/accounting.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('비밀번호는 영문과 숫자 포함 8자 이상만 통과한다', () {
    expect(AuthValidators.isPasswordValid('short1'), isFalse);
    expect(AuthValidators.isPasswordValid('longpassword'), isFalse);
    expect(AuthValidators.isPasswordValid('12345678'), isFalse);
    expect(AuthValidators.isPasswordValid('moa12345'), isTrue);
    expect(AuthValidators.passwordsMatch('moa12345', 'moa12345'), isTrue);
    expect(AuthValidators.passwordsMatch('moa12345', 'moa12346'), isFalse);
  });

  test('필수 약관에 동의해야 가입할 수 있다', () {
    expect(
      AuthValidators.canSubmitSignup(
        name: '백다혜',
        email: 'test12@kau.ac.kr',
        password: 'moa12345',
        confirm: 'moa12345',
        termsAccepted: false,
        privacyAccepted: true,
        needsPassword: true,
      ),
      isFalse,
    );
    expect(
      AuthValidators.canSubmitSignup(
        name: '백다혜',
        email: 'test12@kau.ac.kr',
        password: 'moa12345',
        confirm: 'moa12345',
        termsAccepted: true,
        privacyAccepted: true,
        needsPassword: true,
      ),
      isTrue,
    );
  });

  test('로그인 상태에 따라 처음 화면을 고른다', () {
    expect(
      resolveSession(
        signedIn: false,
        hasProfileName: false,
        hasActiveMembership: false,
        hasPendingMembership: false,
      ),
      SessionDestination.login,
    );
    expect(
      resolveSession(
        signedIn: true,
        hasProfileName: false,
        hasActiveMembership: false,
        hasPendingMembership: false,
      ),
      SessionDestination.signup,
    );
    expect(
      resolveSession(
        signedIn: true,
        hasProfileName: true,
        hasActiveMembership: false,
        hasPendingMembership: true,
      ),
      SessionDestination.pending,
    );
    expect(
      resolveSession(
        signedIn: true,
        hasProfileName: true,
        hasActiveMembership: true,
        hasPendingMembership: true,
      ),
      SessionDestination.home,
    );
    expect(
      resolveSession(
        signedIn: true,
        hasProfileName: true,
        hasActiveMembership: false,
        hasPendingMembership: false,
      ),
      SessionDestination.noClub,
    );
  });

  test('일반 구성원에게는 설정이 보이지 않고 회장 메뉴는 회장만 본다', () {
    expect(ClubAccess.showsSettings(ClubAccess.member), isFalse);
    expect(ClubAccess.showsSettings(ClubAccess.admin), isTrue);
    expect(ClubAccess.showsSettings(ClubAccess.owner), isTrue);
    expect(ClubAccess.isOwner(ClubAccess.admin), isFalse);
    expect(ClubAccess.isOwner(ClubAccess.owner), isTrue);
    expect(ClubAccess.label(ClubAccess.admin), '관리자');
    expect(
      ClubAccess.rank(ClubAccess.owner),
      lessThan(ClubAccess.rank(ClubAccess.member)),
    );
  });

  test('모임은 날짜가 있을 때만 지난 모임으로 가른다', () {
    final now = DateTime(2026, 11, 8);
    final today = _event(id: 'today', startsAt: DateTime(2026, 11, 8));
    final past = _event(id: 'past', startsAt: DateTime(2026, 10, 1));
    final open = _event(
      id: 'open',
      startsAt: DateTime(2026, 10, 1),
      attendanceOpen: true,
    );
    final undated = _event(id: 'plain');
    expect(isPastMeeting(today, now), isFalse);
    expect(isPastMeeting(past, now), isTrue);
    expect(isPastMeeting(open, now), isFalse);
    expect(isPastMeeting(undated, now), isFalse);
    expect(todaysMeetings([today, past], now).map((event) => event.id), [
      'today',
    ]);
    expect(todaysMeetings([undated], now), isEmpty);
    expect(todaysMeetings([open], now), isEmpty);
    expect(todaysMeetings([past], now), isEmpty);
    expect(
      filterMeetings(
        [today, past, undated],
        MeetingFilter.past,
        now,
      ).map((event) => event.id),
      ['past'],
    );
  });

  test('탈퇴 안내는 회장 동아리와 나가는 동아리를 구분한다', () {
    final user = AppUser(
      id: 'u',
      name: '백다혜',
      email: 'a@b.c',
      activityAlerts: true,
      nickname: '다혜',
    );
    final profile = ProfileData(
      user: user,
      options: [
        ClubOption(
          club: _club(id: 'picture', name: '픽쳐 사진동아리', ownerId: 'u'),
          role: 'owner',
          status: 'active',
          primary: true,
        ),
        ClubOption(
          club: _club(id: 'study', name: '주말 코딩 스터디', ownerId: 'other'),
          role: 'member',
          status: 'active',
          primary: false,
        ),
        ClubOption(
          club: _club(id: 'wait', name: '대기', ownerId: 'other'),
          role: 'member',
          status: 'pending',
          primary: false,
        ),
      ],
    );
    expect(profile.user.initial, '다');
    expect(profile.ownedLine, '픽쳐 사진동아리 · 먼저 회장을 넘겨야 해요');
    expect(profile.joinedLine, '2곳에서 자동으로 나가요');
    expect(profile.visibleClubs.map((option) => option.club.id), [
      'picture',
      'study',
    ]);
  });

  test('회장 동아리가 없으면 탈퇴 안내에 없음을 보여 준다', () {
    final user = AppUser(
      id: 'u',
      name: '백다혜',
      email: 'a@b.c',
      activityAlerts: false,
    );
    final profile = ProfileData(user: user, options: const []);
    expect(profile.user.displayNickname, '백다혜');
    expect(profile.ownedLine, '없음');
    expect(profile.joinedLine, '없어요');
  });

  test('초대 코드는 6자리이고 헷갈리는 문자를 빼지 않는다', () {
    final code = generateInviteCode(random: _FixedRandom());
    expect(code.length, 6);
    expect(code.contains(RegExp(r'[IO01]')), isFalse);
  });

  test('출석 QR은 동아리, 모임, 토큰을 담고 다른 QR은 거른다', () {
    final token = generateAttendanceToken(random: _FixedRandom());
    expect(token.length, 24);
    final raw = buildAttendanceQr(clubId: 'club', eventId: 'event', token: token);
    final payload = parseAttendanceQr(' $raw\n');
    expect(payload?.clubId, 'club');
    expect(payload?.eventId, 'event');
    expect(payload?.token, token);
    expect(parseAttendanceQr('moa-attendance:club:event'), isNull);
    expect(parseAttendanceQr('moa-attendance:club::token'), isNull);
    expect(parseAttendanceQr('ABC123'), isNull);
    expect(parseAttendanceQr('https://moa.app/join/ABC123'), isNull);
  });

  test('QR 남은 시간은 분:초로 보여 주고 0 아래로 내려가지 않는다', () {
    expect(formatCountdown(const Duration(minutes: 4, seconds: 32)), '04:32');
    expect(formatCountdown(const Duration(seconds: 5)), '00:05');
    expect(formatCountdown(const Duration(seconds: -3)), '00:00');
    final session = QrSession(token: 't', expiresAt: DateTime(2026, 10, 31, 14, 5));
    expect(session.isExpired(DateTime(2026, 10, 31, 14, 4, 59)), isFalse);
    expect(session.isExpired(DateTime(2026, 10, 31, 14, 5)), isTrue);
    expect(session.remaining(DateTime(2026, 10, 31, 14, 6)), Duration.zero);
  });

  test('학기는 3~8월과 9~2월로 나눈다', () {
    final fall = semesterOf(DateTime(2026, 10, 31));
    expect(fall.start, DateTime(2026, 9));
    expect(fall.end, DateTime(2027, 3));
    expect(fall.contains(DateTime(2027, 2, 28)), isTrue);
    expect(fall.contains(DateTime(2027, 3, 1)), isFalse);
    expect(semesterOf(DateTime(2027, 1, 15)).start, DateTime(2026, 9));
    expect(fall.previous.start, DateTime(2026, 3));
    expect(fall.previous.end, DateTime(2026, 9));
    expect(semesterOf(DateTime(2026, 8, 31)).previous.start, DateTime(2025, 9));
  });

  test('출석률은 참석 대상이었던 모임만 세고 진행 중인 모임은 출석해야 센다', () {
    final now = DateTime(2026, 10, 31, 14, 10);
    final events = [
      for (var day = 1; day <= 6; day++)
        _event(id: 'past$day', startsAt: DateTime(2026, 10, day), attendeeIds: ['me', 'you']),
      _event(id: 'skipped', startsAt: DateTime(2026, 10, 20), attendeeIds: ['you']),
      _event(id: 'today', startsAt: DateTime(2026, 10, 31, 14), attendanceOpen: true, attendeeIds: ['me', 'you']),
    ];
    final records = {
      for (var day = 1; day <= 5; day++) 'past$day': [_record('me'), _record('you')],
      'past6': [_record('you')],
      'skipped': [_record('me')],
    };
    final before = attendanceRateFor(userId: 'me', events: events, records: records, now: now);
    expect((before.attended, before.total, before.percent), (5, 6, 83));

    final after = attendanceRateFor(
      userId: 'me',
      events: events,
      records: {...records, 'today': [_record('me')]},
      now: now,
    );
    expect((after.attended, after.total, after.percent), (6, 7, 86));
    expect(attendanceRateFor(userId: 'nobody', events: events, records: records, now: now).percent, isNull);
    expect(countedMeetings(events: events, records: records, now: now), 7);

    final rates = memberRates(
      members: [_member('me', '백다혜'), _member('you', '김지우'), _member('new', '신입')],
      events: events,
      records: records,
      now: now,
    );
    expect(rates.map((rate) => rate.userId), ['me', 'you']);
    expect(sortRates(rates, highFirst: true).first.userId, 'you');
    expect(sortRates(rates, highFirst: false).first.userId, 'me');
    final average = averageRate(rates);
    expect((average.attended, average.total), (11, 13));
  });

  test('출석 수는 참석 대상의 기록만 센다', () {
    final event = _event(id: 'e', attendeeIds: ['a', 'b']);
    final present = presentRecords(event, [_record('a'), _record('gone')]);
    expect(present.map((record) => record.userId), ['a']);
  });

  test('출석 탭은 출석이 열린 모임을 먼저, 그다음 가까운 모임을 고른다', () {
    final now = DateTime(2026, 10, 31, 9);
    final past = _event(id: 'past', startsAt: DateTime(2026, 10, 24, 18));
    final older = _event(id: 'older', startsAt: DateTime(2026, 10, 17, 18));
    final today = _event(id: 'today', startsAt: DateTime(2026, 10, 31, 14));
    final next = _event(id: 'next', startsAt: DateTime(2026, 11, 7, 14));
    final open = _event(id: 'open', startsAt: DateTime(2026, 10, 30, 14), attendanceOpen: true);
    final undated = _event(id: 'plain');

    expect(currentAttendanceEvent([past, next, today], now)?.id, 'today');
    expect(currentAttendanceEvent([past, next, today, open], now)?.id, 'open');
    expect(currentAttendanceEvent([past, next], now)?.id, 'next');
    expect(currentAttendanceEvent([past, undated], now), isNull);
    expect(
      recentAttendanceEvents([older, undated, next, past, open, today], now).map((event) => event.id),
      ['open', 'today', 'next', 'past', 'older'],
    );
    expect(
      attendanceHistoryIds([
        _event(id: 'counted', startsAt: DateTime(2026, 9, 5), checkedInCount: 3),
        _event(id: 'empty', startsAt: DateTime(2026, 9, 12)),
        _event(id: 'spring', startsAt: DateTime(2026, 4, 5), checkedInCount: 2),
        _event(id: 'old', startsAt: DateTime(2025, 10, 5), checkedInCount: 2),
        open,
      ], now),
      ['counted', 'spring', 'open'],
    );
  });

  test('일반 부원은 자기 회비만 보고 운영진은 전체 회비를 본다', () {
    final payments = [
      _payment('me', 'unpaid'),
      _payment('other', 'paid'),
    ];
    expect(
      visibleDuesPayments(role: 'member', userId: 'me', payments: payments).map((payment) => payment.userId),
      ['me'],
    );
    expect(
      visibleDuesPayments(role: 'admin', userId: 'me', payments: payments),
      hasLength(2),
    );
    expect(
      visibleDuesPayments(role: 'owner', userId: 'me', payments: payments),
      hasLength(2),
    );
  });

  test('장부 기록은 운영진만 할 수 있고 잔액은 수입에서 지출을 뺀다', () {
    expect(canRecordLedger('member'), isFalse);
    expect(canRecordLedger('admin'), isTrue);
    expect(canRecordLedger('owner'), isTrue);
    final entries = [
      _entry('in', LedgerKind.income, 20000, DateTime(2026, 11, 2)),
      _entry('out', LedgerKind.expense, 8000, DateTime(2026, 11, 3)),
      _entry('old', LedgerKind.income, 1000, DateTime(2026, 10, 1)),
    ];
    expect(ledgerBalance(entries), 13000);
    expect(monthLedgerTotals(entries, DateTime(2026, 11)).income, 20000);
    expect(monthLedgerTotals(entries, DateTime(2026, 11)).expense, 8000);
    final progress = duesProgress([
      _payment('a', DuesStatus.paid, amount: 10000),
      _payment('b', DuesStatus.unpaid, amount: 10000),
    ]);
    expect(progress.percent, 50);
    expect(progress.unpaidCount, 1);
  });

  test('정산 지원금은 앞 차수부터 빼고 나머지는 앞 사람에게 1원씩 더한다', () {
    final split = splitSettlement(
      supportAmount: 20000,
      rounds: const [
        RoundSplitInput(id: 'a', index: 1, amount: 120000, attendeeIds: ['u1', 'u2', 'u3', 'u4', 'u5', 'u6', 'u7', 'u8', 'u9', 'u10']),
        RoundSplitInput(id: 'b', index: 2, amount: 54000, attendeeIds: ['u1', 'u2', 'u3', 'u4', 'u5', 'u6']),
      ],
    );
    expect(split.totalSpend, 174000);
    expect(split.supportApplied, 20000);
    expect(split.personalTotal, 154000);
    expect(split.rounds.first.supportApplied, 20000);
    expect(split.rounds.first.net, 100000);
    expect(split.rounds.first.representativeShare, 10000);
    expect(split.rounds.last.representativeShare, 9000);
    final both = split.people.firstWhere((person) => person.userId == 'u1');
    final firstOnly = split.people.firstWhere((person) => person.userId == 'u7');
    expect(both.amount, 19000);
    expect(both.roundAmounts, [10000, 9000]);
    expect(firstOnly.amount, 10000);
    expect(split.groups.map((group) => group.label).toList(), ['1·2차 참석 (6명)', '1차만 참석 (4명)']);

    final remainder = splitWon(100, ['a', 'b', 'c']);
    expect(remainder, {'a': 34, 'b': 33, 'c': 33});
    expect(remainder.values.reduce((sum, amount) => sum + amount), 100);

    final covered = splitSettlement(
      supportAmount: 200000,
      rounds: const [RoundSplitInput(id: 'a', index: 1, amount: 120000, attendeeIds: ['u1'])],
    );
    expect(covered.supportApplied, 120000);
    expect(covered.people, isEmpty);
    expect(
      settlementReadyIssue(const [], supportAmount: 0),
      '차수를 하나 이상 입력해 주세요.',
    );
  });
}

AttendanceRecord _record(String userId) {
  return AttendanceRecord(
    userId: userId,
    userName: userId,
    method: AttendanceMethod.qr,
    checkedAt: DateTime(2026, 10, 1, 14),
  );
}

ClubMember _member(String id, String name) {
  return ClubMember(userId: id, userName: name, role: 'member', status: 'active');
}

Club _club({
  required String id,
  required String name,
  required String ownerId,
}) {
  return Club(
    id: id,
    name: name,
    tagline: '',
    category: '동아리',
    joinPolicy: 'open',
    ownerId: ownerId,
    ownerName: '회장',
    memberCount: 1,
    balance: 0,
    duesPaidCount: 0,
    duesTotalCount: 0,
    duesMonthLabel: '',
  );
}

ClubEvent _event({
  required String id,
  DateTime? startsAt,
  bool attendanceOpen = false,
  List<String> attendeeIds = const [],
  int checkedInCount = 0,
}) {
  return ClubEvent(
    id: id,
    badge: '',
    title: id,
    schedule: '',
    artKicker: '',
    artTitle: '',
    startsAt: startsAt,
    attendanceOpen: attendanceOpen,
    attendeeIds: attendeeIds,
    checkedInCount: checkedInCount,
  );
}

DuesPayment _payment(String userId, String status, {int amount = 20000}) {
  return DuesPayment(
    userId: userId,
    userName: userId,
    duesId: 'nov',
    duesTitle: '11월 회비',
    amount: amount,
    status: status,
  );
}

LedgerEntry _entry(String id, String kind, int amount, DateTime occurredAt) {
  return LedgerEntry(
    id: id,
    kind: kind,
    amount: amount,
    title: id,
    occurredAt: occurredAt,
    category: '기타',
    memo: '',
    actorId: 'owner',
    actorName: '회장',
  );
}

class _FixedRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
