import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/club.dart';
import 'package:flutter_proj/router/app_routes.dart';

const inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String generateInviteCode({int length = 6, Random? random}) {
  final rng = random ?? Random.secure();
  return List.generate(
    length,
    (_) => inviteAlphabet[rng.nextInt(inviteAlphabet.length)],
  ).join();
}

class FirebaseClubService implements ClubGateway {
  FirebaseClubService(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _clubs => _db.collection('clubs');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _db.collection('inviteCodes');

  @override
  Future<void> ensureUser({
    required String id,
    required String name,
    required String email,
    bool activityAlerts = false,
  }) async {
    final ref = _users.doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': name.trim(),
        'email': email.trim(),
        'activityAlerts': activityAlerts,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    final data = snap.data() ?? {};
    final updates = <String, dynamic>{};
    if ((data['name'] as String? ?? '').trim().isEmpty && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
    }
    if ((data['email'] as String? ?? '').trim().isEmpty && email.trim().isNotEmpty) {
      updates['email'] = email.trim();
    }
    if (updates.isNotEmpty) await ref.update(updates);
  }

  @override
  Future<AppUser?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return _userFrom(snap);
  }

  @override
  Future<LaunchTarget> launchFor(String uid) async {
    final user = await getUser(uid);
    if (user == null || user.name.trim().isEmpty) {
      return const LaunchTarget(AppRoutes.signup, SignupMode.complete);
    }
    final mirrors = await _users.doc(uid).collection('memberships').get();
    final active = mirrors.docs.where((doc) => doc.data()['status'] == 'active');
    if (active.isNotEmpty) {
      return LaunchTarget(AppRoutes.home, HomeArgs(active.first.id));
    }
    final pending = mirrors.docs.where((doc) => doc.data()['status'] == 'pending');
    if (pending.isNotEmpty) {
      return LaunchTarget(AppRoutes.joinPending, ClubArgs(pending.first.id));
    }
    return const LaunchTarget(AppRoutes.noClub);
  }

  @override
  Future<CreatedClub> createClub({
    required String ownerId,
    required String ownerName,
    required String name,
    required String tagline,
    required String category,
    required String joinPolicy,
    int? feeAmount,
    ImagePayload? image,
  }) async {
    final clubRef = _clubs.doc();
    final code = generateInviteCode();
    final expiresAt = DateTime.now().add(const Duration(days: 30));
    final club = Club(
      id: clubRef.id,
      name: name.trim(),
      tagline: tagline.trim(),
      category: category,
      joinPolicy: joinPolicy,
      feeAmount: feeAmount,
      ownerId: ownerId,
      ownerName: ownerName.trim(),
      memberCount: 1,
      balance: 0,
      duesPaidCount: 0,
      duesTotalCount: 1,
      duesMonthLabel: '',
      inviteCode: code,
      inviteExpiresAt: expiresAt,
    );
    await clubRef.set(_clubToMap(club));
    final batch = _db.batch();
    batch.set(clubRef.collection('members').doc(ownerId), {
      'userId': ownerId,
      'userName': ownerName.trim(),
      'role': 'owner',
      'status': 'active',
      'feeReported': false,
      'requestedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_users.doc(ownerId).collection('memberships').doc(clubRef.id), {
      'clubId': clubRef.id,
      'role': 'owner',
      'status': 'active',
    });
    await batch.commit();
    await _invites.doc(code).set({
      'clubId': clubRef.id,
      'ownerId': ownerId,
      'expiresAt': Timestamp.fromDate(expiresAt),
    });

    var saved = club;
    if (image != null) {
      final url = await _upload(clubRef.id, image);
      await clubRef.update({'imageUrl': url});
      saved = Club(
        id: club.id,
        name: club.name,
        tagline: club.tagline,
        category: club.category,
        joinPolicy: club.joinPolicy,
        feeAmount: club.feeAmount,
        imageUrl: url,
        ownerId: club.ownerId,
        ownerName: club.ownerName,
        memberCount: club.memberCount,
        balance: club.balance,
        duesPaidCount: club.duesPaidCount,
        duesTotalCount: club.duesTotalCount,
        duesMonthLabel: club.duesMonthLabel,
        inviteCode: club.inviteCode,
        inviteExpiresAt: club.inviteExpiresAt,
      );
    }
    return CreatedClub(
      club: saved,
      invite: InviteCode(code: code, clubId: clubRef.id, expiresAt: expiresAt),
    );
  }

  @override
  Future<ClubPreview?> findByCode(String code) async {
    final snap = await _invites.doc(code.trim().toUpperCase()).get();
    if (!snap.exists) return null;
    final data = snap.data() ?? {};
    final expiresAt = _date(data['expiresAt']);
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) return null;
    final clubId = data['clubId'] as String?;
    if (clubId == null) return null;
    final club = await _readClub(clubId);
    if (club == null) return null;
    return ClubPreview(club: club, memberCount: club.memberCount);
  }

  @override
  Future<void> joinImmediately({
    required String uid,
    required String userName,
    required Club club,
  }) async {
    await _writeMember(
      uid: uid,
      userName: userName,
      club: club,
      status: 'active',
      depositName: null,
      feeReported: false,
    );
    await _clubs.doc(club.id).update({'memberCount': FieldValue.increment(1)});
  }

  @override
  Future<void> requestJoin({
    required String uid,
    required String userName,
    required Club club,
    required String depositName,
    required bool feeReported,
  }) async {
    await _writeMember(
      uid: uid,
      userName: userName,
      club: club,
      status: 'pending',
      depositName: depositName,
      feeReported: feeReported,
    );
    await _clubs.doc(club.id).collection('notices').add({
      'title': '새 가입 요청',
      'body': '$userName님이 가입을 신청했어요',
      'kind': 'join',
      'unread': true,
      'actorId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<PendingView> loadPending({
    required String uid,
    required String clubId,
  }) async {
    final club = await _readClub(clubId);
    final memberSnap = await _clubs.doc(clubId).collection('members').doc(uid).get();
    if (club == null || !memberSnap.exists) {
      throw StateError('가입 신청을 찾을 수 없어요.');
    }
    return PendingView(club: club, membership: _memberFrom(clubId, memberSnap));
  }

  @override
  Future<void> cancelJoin({required String uid, required String clubId}) async {
    final batch = _db.batch();
    batch.delete(_clubs.doc(clubId).collection('members').doc(uid));
    batch.delete(_users.doc(uid).collection('memberships').doc(clubId));
    await batch.commit();
  }

  @override
  Future<void> askOwner({
    required String uid,
    required String userName,
    required String clubId,
  }) async {
    await _clubs.doc(clubId).collection('notices').add({
      'title': '가입 확인 요청',
      'body': '$userName님이 입금 확인을 요청했어요',
      'kind': 'join',
      'unread': true,
      'actorId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<HomeData> loadHome({
    required String uid,
    required String clubId,
  }) async {
    final user = await getUser(uid);
    final club = await _readClub(clubId);
    if (user == null || club == null) {
      throw StateError('동아리 정보를 불러오지 못했어요.');
    }
    final mirrors = await _users.doc(uid).collection('memberships').get();
    final clubs = <Club>[];
    for (final mirror in mirrors.docs) {
      if (mirror.data()['status'] != 'active') continue;
      final item = await _readClub(mirror.id);
      if (item != null) clubs.add(item);
    }
    final events = await _mapDocs(
      _clubs.doc(clubId).collection('events'),
      (doc) => ClubEvent(
        id: doc.id,
        badge: doc.data()['badge'] as String? ?? '',
        title: doc.data()['title'] as String? ?? '',
        schedule: doc.data()['schedule'] as String? ?? '',
        artKicker: doc.data()['artKicker'] as String? ?? '',
        artTitle: doc.data()['artTitle'] as String? ?? '',
        attendanceOpen: doc.data()['attendanceOpen'] as bool? ?? false,
        attendeeInitials: _strings(doc.data()['attendeeInitials']),
        attendeeSummary: doc.data()['attendeeSummary'] as String? ?? '',
      ),
    );
    final activities = await _mapDocs(
      _clubs.doc(clubId).collection('activities'),
      (doc) => ActivityItem(
        id: doc.id,
        title: doc.data()['title'] as String? ?? '',
        subtitle: doc.data()['subtitle'] as String? ?? '',
        amount: (doc.data()['amount'] as num?)?.toInt() ?? 0,
        amountNote: doc.data()['amountNote'] as String? ?? '',
      ),
    );
    final notices = await _mapDocs(
      _clubs.doc(clubId).collection('notices'),
      (doc) => ClubNotice(
        id: doc.id,
        title: doc.data()['title'] as String? ?? '',
        body: doc.data()['body'] as String? ?? '',
        createdAt: _date(doc.data()['createdAt']) ?? DateTime.now(),
        unread: doc.data()['unread'] as bool? ?? false,
        kind: doc.data()['kind'] as String? ?? 'info',
      ),
    );
    notices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final pending = await _clubs
        .doc(clubId)
        .collection('members')
        .where('status', isEqualTo: 'pending')
        .get();
    final tasks = <HomeTask>[
      if (club.ownerId == uid && pending.docs.isNotEmpty)
        HomeTask(
          id: 'pending-joins',
          title: '새 가입 요청이 있어요',
          subtitle: '가입 신청 ${pending.docs.length}명',
          kind: 'join',
          count: pending.docs.length,
        ),
    ];
    return HomeData(
      user: user,
      club: club,
      clubs: clubs.isEmpty ? [club] : clubs,
      events: events,
      activities: activities,
      notices: notices,
      tasks: tasks,
    );
  }

  @override
  Future<void> markNoticesRead(String clubId) async {
    final snap = await _clubs
        .doc(clubId)
        .collection('notices')
        .where('unread', isEqualTo: true)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'unread': false});
    }
    await batch.commit();
  }

  Future<void> _writeMember({
    required String uid,
    required String userName,
    required Club club,
    required String status,
    required String? depositName,
    required bool feeReported,
  }) async {
    final batch = _db.batch();
    batch.set(_clubs.doc(club.id).collection('members').doc(uid), {
      'userId': uid,
      'userName': userName.trim(),
      'role': 'member',
      'status': status,
      'depositName': depositName?.trim(),
      'feeReported': feeReported,
      'requestedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_users.doc(uid).collection('memberships').doc(club.id), {
      'clubId': club.id,
      'role': 'member',
      'status': status,
    });
    await batch.commit();
  }

  Future<String> _upload(String clubId, ImagePayload image) async {
    final ref = _storage.ref('clubs/$clubId/cover');
    await ref.putData(
      Uint8List.fromList(image.bytes),
      SettableMetadata(contentType: image.contentType),
    );
    return ref.getDownloadURL();
  }

  Future<Club?> _readClub(String clubId) async {
    final snap = await _clubs.doc(clubId).get();
    if (!snap.exists) return null;
    return _clubFrom(snap);
  }

  Future<List<T>> _mapDocs<T>(
    CollectionReference<Map<String, dynamic>> collection,
    T Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) map,
  ) async {
    final snap = await collection.get();
    return snap.docs.map(map).toList();
  }

  Map<String, dynamic> _clubToMap(Club club) {
    return {
      'name': club.name,
      'tagline': club.tagline,
      'category': club.category,
      'joinPolicy': club.joinPolicy,
      if (club.feeAmount != null) 'feeAmount': club.feeAmount,
      'ownerId': club.ownerId,
      'ownerName': club.ownerName,
      'memberCount': club.memberCount,
      'balance': club.balance,
      'duesPaidCount': club.duesPaidCount,
      'duesTotalCount': club.duesTotalCount,
      'duesMonthLabel': club.duesMonthLabel,
      'inviteCode': club.inviteCode,
      if (club.inviteExpiresAt != null)
        'inviteExpiresAt': Timestamp.fromDate(club.inviteExpiresAt!),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AppUser _userFrom(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? {};
    return AppUser(
      id: snap.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      activityAlerts: data['activityAlerts'] as bool? ?? false,
    );
  }

  Club _clubFrom(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? {};
    return Club(
      id: snap.id,
      name: data['name'] as String? ?? '',
      tagline: data['tagline'] as String? ?? '',
      category: data['category'] as String? ?? '동아리',
      joinPolicy: data['joinPolicy'] as String? ?? ClubOptions.approval,
      feeAmount: (data['feeAmount'] as num?)?.toInt(),
      imageUrl: data['imageUrl'] as String?,
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      bankName: data['bankName'] as String?,
      bankAccount: data['bankAccount'] as String?,
      accountHolder: data['accountHolder'] as String?,
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      duesPaidCount: (data['duesPaidCount'] as num?)?.toInt() ?? 0,
      duesTotalCount: (data['duesTotalCount'] as num?)?.toInt() ?? 0,
      duesMonthLabel: data['duesMonthLabel'] as String? ?? '',
      inviteCode: data['inviteCode'] as String?,
      inviteExpiresAt: _date(data['inviteExpiresAt']),
    );
  }

  Membership _memberFrom(
    String clubId,
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? {};
    return Membership(
      clubId: clubId,
      userId: data['userId'] as String? ?? snap.id,
      userName: data['userName'] as String? ?? '',
      role: data['role'] as String? ?? 'member',
      status: data['status'] as String? ?? 'pending',
      depositName: data['depositName'] as String?,
      feeReported: data['feeReported'] as bool? ?? false,
      requestedAt: _date(data['requestedAt']),
    );
  }

  DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  List<String> _strings(Object? value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    return const [];
  }
}
