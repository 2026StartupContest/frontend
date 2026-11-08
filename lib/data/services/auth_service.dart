import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService implements AuthGateway {
  FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  String? get currentDisplayName => _auth.currentUser?.displayName;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
  }

  @override
  Future<void> signInWithGoogle() async {
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google ID token was empty',
      );
    }
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  @override
  Future<void> ensureRecentLogin() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('로그인 정보가 없어요.');
    final result = await user.getIdTokenResult();
    final authTime = result.authTime;
    final recent =
        authTime != null &&
        DateTime.now().difference(authTime) < const Duration(minutes: 5);
    if (!recent) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('로그인 정보가 없어요.');
    await user.delete();
  }
}
