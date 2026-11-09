import 'dart:math';

import 'package:flutter_proj/core/auth_validators.dart';
import 'package:flutter_proj/core/club_access.dart';
import 'package:flutter_proj/core/meeting_filter.dart';
import 'package:flutter_proj/core/session_destination.dart';
import 'package:flutter_proj/data/services/club_service.dart';
import 'package:flutter_proj/models/app_user.dart';
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
