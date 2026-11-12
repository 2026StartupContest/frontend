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

class AccountingArgs {
  const AccountingArgs(this.clubId, [this.segment = 'dues', this.mine = false]);

  final String clubId;
  final String segment;
  final bool mine;
}

class LedgerEntryArgs {
  const LedgerEntryArgs({required this.clubId, this.entryId});

  final String clubId;
  final String? entryId;
}

class SettlementArgs {
  const SettlementArgs({
    required this.clubId,
    this.settlementId,
    this.roundId,
    this.openConfirm = false,
  });

  final String clubId;
  final String? settlementId;
  final String? roundId;
  final bool openConfirm;
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
