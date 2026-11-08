class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.activityAlerts,
    this.nickname,
    this.primaryClubId,
  });

  final String id;
  final String name;
  final String email;
  final bool activityAlerts;
  final String? nickname;
  final String? primaryClubId;

  String get displayNickname {
    final nick = nickname?.trim() ?? '';
    if (nick.isNotEmpty) return nick;
    return name;
  }

  String get initial {
    final source = displayNickname.trim();
    if (source.isEmpty) return '모';
    return String.fromCharCode(source.runes.first);
  }
}

enum SignupMode { create, complete }

class SignupDoneArgs {
  const SignupDoneArgs({required this.name, required this.email});

  final String name;
  final String email;
}

class HomeArgs {
  const HomeArgs(this.clubId);

  final String clubId;
}

class ClubArgs {
  const ClubArgs(this.clubId);

  final String clubId;
}

class MeetingArgs {
  const MeetingArgs({
    required this.clubId,
    this.eventId,
    this.role = 'member',
    this.selectedIds = const [],
  });

  final String clubId;
  final String? eventId;
  final String role;
  final List<String> selectedIds;
}
