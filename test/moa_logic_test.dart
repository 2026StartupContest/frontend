import 'dart:math';

import 'package:flutter_proj/core/auth_validators.dart';
import 'package:flutter_proj/core/session_destination.dart';
import 'package:flutter_proj/data/services/club_service.dart';
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

  test('초대 코드는 6자리이고 헷갈리는 문자를 빼지 않는다', () {
    final code = generateInviteCode(random: _FixedRandom());
    expect(code.length, 6);
    expect(code.contains(RegExp(r'[IO01]')), isFalse);
  });
}

class _FixedRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
