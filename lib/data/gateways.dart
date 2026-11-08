import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';

class LaunchTarget {
  const LaunchTarget(this.route, [this.arguments]);

  final String route;
  final Object? arguments;
}

abstract class AuthGateway {
  String? get currentUid;
  String? get currentEmail;
  String? get currentDisplayName;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<void> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

abstract class ClubGateway {
  Future<void> ensureUser({
    required String id,
    required String name,
    required String email,
    bool activityAlerts = false,
  });

  Future<AppUser?> getUser(String uid);

  Future<LaunchTarget> launchFor(String uid);

  Future<CreatedClub> createClub({
    required String ownerId,
    required String ownerName,
    required String name,
    required String tagline,
    required String category,
    required String joinPolicy,
    int? feeAmount,
    ImagePayload? image,
  });

  Future<ClubPreview?> findByCode(String code);

  Future<void> joinImmediately({
    required String uid,
    required String userName,
    required Club club,
  });

  Future<void> requestJoin({
    required String uid,
    required String userName,
    required Club club,
    required String depositName,
    required bool feeReported,
  });

  Future<PendingView> loadPending({
    required String uid,
    required String clubId,
  });

  Future<void> cancelJoin({required String uid, required String clubId});

  Future<void> askOwner({
    required String uid,
    required String userName,
    required String clubId,
  });

  Future<HomeData> loadHome({required String uid, required String clubId});

  Future<void> markNoticesRead(String clubId);
}
