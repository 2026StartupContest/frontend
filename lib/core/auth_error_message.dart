import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

String authErrorMessage(Object error) {
  if (error is GoogleSignInException &&
      error.code == GoogleSignInExceptionCode.canceled) {
    return '';
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => '이메일 형식을 확인해 주세요.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => '이메일 또는 비밀번호가 올바르지 않아요.',
      'email-already-in-use' => '이미 가입된 이메일이에요.',
      'weak-password' => '비밀번호는 영문과 숫자를 포함해 8자 이상이어야 해요.',
      'network-request-failed' => '네트워크 연결을 확인해 주세요.',
      'too-many-requests' => '시도가 너무 많아요. 잠시 후 다시 시도해 주세요.',
      'requires-recent-login' => '다시 로그인한 뒤 탈퇴해 주세요.',
      _ => '로그인에 실패했어요. 잠시 후 다시 시도해 주세요.',
    };
  }
  return '잠시 후 다시 시도해 주세요.';
}
