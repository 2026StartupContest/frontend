abstract final class ClubAccess {
  static const owner = 'owner';
  static const admin = 'admin';
  static const member = 'member';

  static bool showsSettings(String role) => role == owner || role == admin;

  static bool isOwner(String role) => role == owner;

  static String label(String role) => switch (role) {
    owner => '회장',
    admin => '관리자',
    _ => '일반',
  };

  static int rank(String role) => switch (role) {
    owner => 0,
    admin => 1,
    _ => 2,
  };
}
