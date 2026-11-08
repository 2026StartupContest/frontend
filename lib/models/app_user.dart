class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.activityAlerts,
  });

  final String id;
  final String name;
  final String email;
  final bool activityAlerts;
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
