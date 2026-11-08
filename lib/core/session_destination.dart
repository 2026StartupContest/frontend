enum SessionDestination { login, signup, noClub, pending, home }

SessionDestination resolveSession({
  required bool signedIn,
  required bool hasProfileName,
  required bool hasActiveMembership,
  required bool hasPendingMembership,
}) {
  if (!signedIn) return SessionDestination.login;
  if (!hasProfileName) return SessionDestination.signup;
  if (hasActiveMembership) return SessionDestination.home;
  if (hasPendingMembership) return SessionDestination.pending;
  return SessionDestination.noClub;
}
