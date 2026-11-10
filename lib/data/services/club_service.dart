import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_proj/core/attendance.dart';
import 'package:flutter_proj/core/kst.dart';
import 'package:flutter_proj/core/meeting_filter.dart';
import 'package:flutter_proj/data/gateways.dart';
import 'package:flutter_proj/models/app_user.dart';
import 'package:flutter_proj/models/attendance.dart';
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

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _clubs =>
      _db.collection('clubs');
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
    if ((data['name'] as String? ?? '').trim().isEmpty &&
        name.trim().isNotEmpty) {
      updates['name'] = name.trim();
    }
    if ((data['email'] as String? ?? '').trim().isEmpty &&
        email.trim().isNotEmpty) {
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
  Future<ProfileData> loadProfile(String uid) async {
    final user = await getUser(uid);
    if (user == null) throw StateError('계정 정보를 불러오지 못했어요.');
    final mirrors = await _users.doc(uid).collection('memberships').get();
    final options = <ClubOption>[];
    for (final mirror in mirrors.docs) {
      final status = mirror.data()['status'] as String? ?? '';
      if (status != 'active' && status != 'pending') continue;
      final club = await _readClub(mirror.id);
      if (club == null) continue;
      final mirrorRole = mirror.data()['role'] as String? ?? 'member';
      options.add(
        ClubOption(
          club: club,
          role: club.ownerId == uid ? 'owner' : mirrorRole,
          status: status,
          primary: false,
        ),
      );
    }
    final activeIds = options
        .where((option) => !option.isPending)
        .map((option) => option.club.id)
        .toSet();
    final storedPrimary = user.primaryClubId;
    final primaryId = storedPrimary != null && activeIds.contains(storedPrimary)
        ? storedPrimary
        : (activeIds.isEmpty ? null : activeIds.first);
    return ProfileData(
      user: user,
      options: [
        for (final option in options)
          ClubOption(
            club: option.club,
            role: option.role,
            status: option.status,
            primary: option.club.id == primaryId,
          ),
      ],
    );
  }

  @override
  Future<void> updateNickname({
    required String uid,
    required String nickname,
  }) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) throw StateError('닉네임을 입력해 주세요.');
    if (trimmed.length > 30) throw StateError('닉네임은 30자까지 입력할 수 있어요.');
    await _users.doc(uid).update({'nickname': trimmed});
  }

  @override
  Future<void> updateActivityAlerts({
    required String uid,
    required bool enabled,
  }) async {
    await _users.doc(uid).update({'activityAlerts': enabled});
  }

  @override
  Future<void> deleteAccountData(String uid) async {
    final mirrors = await _users.doc(uid).collection('memberships').get();
    for (final mirror in mirrors.docs) {
      final club = await _readClub(mirror.id);
      final member = await _clubs
          .doc(mirror.id)
          .collection('members')
          .doc(uid)
          .get();
      final role =
          member.data()?['role'] as String? ??
          mirror.data()['role'] as String? ??
          'member';
      if (club?.ownerId == uid || role == 'owner') {
        throw StateError('먼저 회장을 넘겨야 해요.');
      }
    }
    for (final mirror in mirrors.docs) {
      await removeMember(clubId: mirror.id, userId: uid);
    }
    final leftover = await _users.doc(uid).collection('memberships').get();
    await _deleteRefs(leftover.docs.map((doc) => doc.reference).toList());
    await _users.doc(uid).delete();
  }

  @override
  Future<LaunchTarget> launchFor(String uid) async {
    final user = await getUser(uid);
    if (user == null || user.name.trim().isEmpty) {
      return const LaunchTarget(AppRoutes.signup, SignupMode.complete);
    }
    final mirrors = await _users.doc(uid).collection('memberships').get();
    final active = mirrors.docs
        .where((doc) => doc.data()['status'] == 'active')
        .toList();
    if (active.isNotEmpty) {
      final primary = user.primaryClubId;
      final chosen = active.where((doc) => doc.id == primary);
      final id = chosen.isEmpty ? active.first.id : chosen.first.id;
      return LaunchTarget(AppRoutes.home, HomeArgs(id));
    }
    final pending = mirrors.docs.where(
      (doc) => doc.data()['status'] == 'pending',
    );
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
      final url = await _uploadBytes('clubs/${clubRef.id}/cover', image);
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
    final memberSnap = await _clubs
        .doc(clubId)
        .collection('members')
        .doc(uid)
        .get();
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
    final options = <ClubOption>[];
    String role = 'member';
    for (final mirror in mirrors.docs) {
      final status = mirror.data()['status'] as String? ?? '';
      if (status != 'active' && status != 'pending') continue;
      final item = await _readClub(mirror.id);
      if (item == null) continue;
      final mirrorRole = mirror.data()['role'] as String? ?? 'member';
      if (mirror.id == clubId) role = mirrorRole;
      options.add(
        ClubOption(
          club: item,
          role: item.ownerId == uid ? 'owner' : mirrorRole,
          status: status,
          primary: false,
        ),
      );
    }
    if (club.ownerId == uid) role = 'owner';
    if (options.every((option) => option.club.id != club.id)) {
      options.insert(
        0,
        ClubOption(club: club, role: role, status: 'active', primary: false),
      );
    }
    final activeIds = options
        .where((option) => !option.isPending)
        .map((option) => option.club.id);
    final storedPrimary = user.primaryClubId;
    final primaryId = storedPrimary != null && activeIds.contains(storedPrimary)
        ? storedPrimary
        : activeIds.cast<String?>().firstWhere(
            (id) => id != null,
            orElse: () => null,
          );
    final marked = [
      for (final option in options)
        ClubOption(
          club: option.club,
          role: option.role,
          status: option.status,
          primary: option.club.id == primaryId,
        ),
    ];
    final clubs = marked
        .where((option) => !option.isPending)
        .map((option) => option.club)
        .toList();
    final events = uniqueMeetings(
      await _mapDocs(_clubs.doc(clubId).collection('events'), _eventFrom),
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
        createdAt: _kst(doc.data()['createdAt']) ?? kstNow(),
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
    final reported = pending.docs
        .where((doc) => doc.data()['feeReported'] == true)
        .length;
    final unpaid = pending.docs.length - reported;
    final tasks = <HomeTask>[
      if (role == 'owner' && pending.docs.isNotEmpty)
        HomeTask(
          id: 'pending-joins',
          title: '새 가입 요청이 있어요',
          subtitle: '입금 신고 $reported명 · 미입금 $unpaid명',
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
      role: role,
      options: marked.isEmpty
          ? [
              ClubOption(
                club: club,
                role: role,
                status: 'active',
                primary: true,
              ),
            ]
          : marked,
      primaryClubId: primaryId,
    );
  }

  @override
  Future<ClubDesk> loadDesk({
    required String uid,
    required String clubId,
  }) async {
    final user = await getUser(uid);
    final club = await _readClub(clubId);
    if (user == null || club == null) {
      throw StateError('동아리 정보를 불러오지 못했어요.');
    }
    final memberSnap = await _clubs
        .doc(clubId)
        .collection('members')
        .doc(uid)
        .get();
    var role = memberSnap.data()?['role'] as String? ?? 'member';
    if (club.ownerId == uid) role = 'owner';
    final members = await _mapDocs(_clubs.doc(clubId).collection('members'), (
      doc,
    ) {
      final data = doc.data();
      return ClubMember(
        userId: data['userId'] as String? ?? doc.id,
        userName: data['userName'] as String? ?? '',
        role: data['role'] as String? ?? 'member',
        status: data['status'] as String? ?? 'active',
        duty: data['duty'] as String?,
        joinedAt: _date(data['joinedAt']) ?? _date(data['requestedAt']),
        unpaidDues: (data['unpaidDues'] as num?)?.toInt(),
        unsettledAmount: (data['unsettledAmount'] as num?)?.toInt(),
      );
    });
    final active = members.where((member) => member.status == 'active').toList()
      ..sort((a, b) {
        final rank = _roleRank(a.role).compareTo(_roleRank(b.role));
        if (rank != 0) return rank;
        return a.userName.compareTo(b.userName);
      });
    final requests = members
        .where((member) => member.status == 'pending')
        .map(
          (member) => Membership(
            clubId: clubId,
            userId: member.userId,
            userName: member.userName,
            role: member.role,
            status: member.status,
            feeReported: false,
            requestedAt: member.joinedAt,
          ),
        )
        .toList();
    final pendingDocs = await _clubs
        .doc(clubId)
        .collection('members')
        .where('status', isEqualTo: 'pending')
        .get();
    final pending =
        pendingDocs.docs.map((doc) => _memberFrom(clubId, doc)).toList()..sort(
          (a, b) => (b.requestedAt ?? DateTime(0)).compareTo(
            a.requestedAt ?? DateTime(0),
          ),
        );
    return ClubDesk(
      user: user,
      club: club,
      myRole: role,
      members: active,
      requests: pending.isNotEmpty ? pending : requests,
    );
  }

  @override
  Future<void> setPrimaryClub({
    required String uid,
    required String clubId,
  }) async {
    await _users.doc(uid).update({'primaryClubId': clubId});
  }

  @override
  Future<void> updateClubName({
    required String clubId,
    required String name,
    ImagePayload? image,
  }) async {
    final trimmed = name.trim();
    if (image == null) {
      await _clubs.doc(clubId).update({'name': trimmed});
      return;
    }
    final url = await _uploadBytes('clubs/$clubId/cover', image);
    await _clubs.doc(clubId).update({'name': trimmed, 'imageUrl': url});
  }

  @override
  Future<void> updateJoinPolicy({
    required String clubId,
    required String joinPolicy,
  }) async {
    await _clubs.doc(clubId).update({'joinPolicy': joinPolicy});
  }

  @override
  Future<void> updateFeeAmount({
    required String clubId,
    required int? feeAmount,
  }) async {
    if (feeAmount == null) {
      await _clubs.doc(clubId).update({'feeAmount': FieldValue.delete()});
      return;
    }
    await _clubs.doc(clubId).update({'feeAmount': feeAmount});
  }

  @override
  Future<String> reissueInvite({required String clubId}) async {
    final club = await _readClub(clubId);
    if (club == null) throw StateError('동아리를 찾을 수 없어요.');
    final previous = club.inviteCode;
    if (previous != null && previous.isNotEmpty) {
      await _invites.doc(previous).delete();
    }
    final code = generateInviteCode();
    final expiresAt = DateTime.now().add(const Duration(days: 30));
    await _invites.doc(code).set({
      'clubId': clubId,
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
    await _clubs.doc(clubId).update({
      'inviteCode': code,
      'inviteExpiresAt': Timestamp.fromDate(expiresAt),
    });
    return code;
  }

  @override
  Future<void> setMemberRole({
    required String clubId,
    required String userId,
    required String role,
  }) async {
    if (role != 'admin' && role != 'member') {
      throw StateError('그 역할로는 바꿀 수 없어요.');
    }
    final ref = _clubs.doc(clubId).collection('members').doc(userId);
    final snap = await ref.get();
    if (!snap.exists) throw StateError('구성원을 찾을 수 없어요.');
    if (snap.data()?['role'] == 'owner') {
      throw StateError('회장 역할은 넘기기로만 바꿀 수 있어요.');
    }
    final batch = _db.batch();
    batch.update(ref, {'role': role});
    batch.update(_users.doc(userId).collection('memberships').doc(clubId), {
      'role': role,
    });
    await batch.commit();
  }

  @override
  Future<void> transferOwnership({
    required String clubId,
    required String fromUserId,
    required String toUserId,
  }) async {
    final club = await _readClub(clubId);
    if (club == null || club.ownerId != fromUserId) {
      throw StateError('회장만 권한을 넘길 수 있어요.');
    }
    final target = await _clubs
        .doc(clubId)
        .collection('members')
        .doc(toUserId)
        .get();
    if (!target.exists || target.data()?['status'] != 'active') {
      throw StateError('활동 중인 구성원에게만 넘길 수 있어요.');
    }
    final toName = target.data()?['userName'] as String? ?? '';
    final batch = _db.batch();
    batch.update(_clubs.doc(clubId), {
      'ownerId': toUserId,
      'ownerName': toName,
    });
    batch.update(_clubs.doc(clubId).collection('members').doc(fromUserId), {
      'role': 'admin',
    });
    batch.update(_clubs.doc(clubId).collection('members').doc(toUserId), {
      'role': 'owner',
    });
    batch.update(_users.doc(fromUserId).collection('memberships').doc(clubId), {
      'role': 'admin',
    });
    batch.update(_users.doc(toUserId).collection('memberships').doc(clubId), {
      'role': 'owner',
    });
    batch.set(_clubs.doc(clubId).collection('notices').doc(), {
      'title': '회장이 바뀌었어요',
      'body': '$toName님이 새 회장이에요',
      'kind': 'info',
      'unread': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> removeMember({
    required String clubId,
    required String userId,
  }) async {
    final ref = _clubs.doc(clubId).collection('members').doc(userId);
    final snap = await ref.get();
    if (!snap.exists) return;
    if (snap.data()?['role'] == 'owner') {
      throw StateError('회장은 내보낼 수 없어요.');
    }
    final batch = _db.batch();
    batch.delete(ref);
    batch.delete(_users.doc(userId).collection('memberships').doc(clubId));
    if (snap.data()?['status'] == 'active') {
      batch.update(_clubs.doc(clubId), {
        'memberCount': FieldValue.increment(-1),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> approveJoins({
    required String clubId,
    required List<String> userIds,
  }) async {
    if (userIds.isEmpty) return;
    final batch = _db.batch();
    for (final userId in userIds) {
      batch.update(_clubs.doc(clubId).collection('members').doc(userId), {
        'status': 'active',
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      batch.set(_users.doc(userId).collection('memberships').doc(clubId), {
        'clubId': clubId,
        'role': 'member',
        'status': 'active',
      });
    }
    batch.update(_clubs.doc(clubId), {
      'memberCount': FieldValue.increment(userIds.length),
    });
    batch.set(_clubs.doc(clubId).collection('notices').doc(), {
      'title': '가입을 승인했어요',
      'body': '${userIds.length}명의 가입을 승인했어요',
      'kind': 'join',
      'unread': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> rejectJoins({
    required String clubId,
    required List<String> userIds,
  }) async {
    if (userIds.isEmpty) return;
    final batch = _db.batch();
    for (final userId in userIds) {
      batch.delete(_clubs.doc(clubId).collection('members').doc(userId));
      batch.delete(_users.doc(userId).collection('memberships').doc(clubId));
    }
    await batch.commit();
  }

  @override
  Future<String?> deleteClub({
    required String uid,
    required String clubId,
  }) async {
    final club = await _readClub(clubId);
    if (club == null) return null;
    if (club.ownerId != uid) throw StateError('회장만 동아리를 삭제할 수 있어요.');
    final mirrors = await _users.doc(uid).collection('memberships').get();
    final next = mirrors.docs
        .where((doc) => doc.id != clubId && doc.data()['status'] == 'active')
        .map((doc) => doc.id)
        .cast<String?>()
        .firstWhere((id) => id != null, orElse: () => null);
    final members = await _clubs.doc(clubId).collection('members').get();
    final refs = <DocumentReference<Map<String, dynamic>>>[
      for (final doc in members.docs) ...[
        doc.reference,
        _users
            .doc(doc.data()['userId'] as String? ?? doc.id)
            .collection('memberships')
            .doc(clubId),
      ],
    ];
    for (final name in ['events', 'activities', 'notices']) {
      final snap = await _clubs.doc(clubId).collection(name).get();
      if (name == 'events') {
        for (final doc in snap.docs) {
          refs.addAll(await _attendanceRefs(doc.reference));
        }
      }
      refs.addAll(snap.docs.map((doc) => doc.reference));
    }
    await _deleteRefs(refs);
    if (club.inviteCode != null && club.inviteCode!.isNotEmpty) {
      await _invites.doc(club.inviteCode).delete();
    }
    await _clubs.doc(clubId).delete();
    if (next != null) {
      await _users.doc(uid).update({'primaryClubId': next});
    } else {
      await _users.doc(uid).update({'primaryClubId': FieldValue.delete()});
    }
    return next;
  }

  @override
  Future<ClubEvent> loadEvent({
    required String clubId,
    required String eventId,
  }) async {
    final snap = await _clubs
        .doc(clubId)
        .collection('events')
        .doc(eventId)
        .get();
    if (!snap.exists) throw StateError('모임을 찾을 수 없어요.');
    return _eventFrom(snap);
  }

  @override
  Future<String> saveMeeting({
    required String clubId,
    required ClubEvent event,
    ImagePayload? image,
  }) async {
    final ref = event.id.isEmpty
        ? _clubs.doc(clubId).collection('events').doc()
        : _clubs.doc(clubId).collection('events').doc(event.id);
    final names = await _attendeeNames(clubId, event.attendeeIds);
    final open = event.status == '진행 중';
    final payload = <String, dynamic>{
      'title': event.title.trim(),
      'badge': event.badge,
      'description': event.description.trim(),
      'schedule': event.schedule,
      'artKicker': event.artKicker.isEmpty
          ? event.badge.toUpperCase()
          : event.artKicker,
      'artTitle': event.artTitle.isEmpty ? event.title.trim() : event.artTitle,
      'place': event.place.trim(),
      'supplies': event.supplies.trim(),
      'status': event.status.isEmpty ? '예정' : event.status,
      // 이미 있는 모임의 출석 상태와 출석 수는 출석 흐름에서만 바꿉니다.
      // 수정 화면이 열려 있는 동안 들어온 출석을 덮어쓰지 않으려는 것입니다.
      if (event.id.isEmpty) ...{'attendanceOpen': open, 'checkedInCount': 0},
      'attendeeIds': event.attendeeIds,
      'attendeeInitials': names
          .map(
            (name) =>
                name.isEmpty ? '모' : String.fromCharCode(name.runes.first),
          )
          .take(6)
          .toList(),
      'attendeeSummary': _attendeeSummary(names),
      'feePaidCount': event.feePaidCount,
      if (image == null && event.imageUrl != null && event.imageUrl!.isNotEmpty)
        'imageUrl': event.imageUrl,
    };
    void putOptional(String key, Object? value) {
      if (value != null) {
        payload[key] = value;
      } else if (event.id.isNotEmpty) {
        payload[key] = FieldValue.delete();
      }
    }

    putOptional(
      'startsAt',
      event.startsAt == null
          ? null
          : Timestamp.fromDate(kstWallToInstant(event.startsAt!)),
    );
    putOptional(
      'endsAt',
      event.endsAt == null
          ? null
          : Timestamp.fromDate(kstWallToInstant(event.endsAt!)),
    );
    putOptional('feeAmount', event.feeAmount);
    putOptional(
      'feeDueAt',
      event.feeDueAt == null
          ? null
          : Timestamp.fromDate(kstWallToInstant(event.feeDueAt!)),
    );
    await ref.set(payload, SetOptions(merge: true));
    if (image != null) {
      final url = await _uploadBytes('clubs/$clubId/events/${ref.id}', image);
      await ref.update({'imageUrl': url});
    }
    return ref.id;
  }

  @override
  Future<void> setMeetingStatus({
    required String clubId,
    required String eventId,
    required String status,
  }) async {
    await _clubs.doc(clubId).collection('events').doc(eventId).update({
      'status': status,
      'attendanceOpen': status == '진행 중',
    });
  }

  @override
  Future<void> setMeetingAttendees({
    required String clubId,
    required String eventId,
    required List<String> attendeeIds,
  }) async {
    final names = await _attendeeNames(clubId, attendeeIds);
    await _clubs.doc(clubId).collection('events').doc(eventId).update({
      'attendeeIds': attendeeIds,
      'attendeeInitials': names
          .map(
            (name) =>
                name.isEmpty ? '모' : String.fromCharCode(name.runes.first),
          )
          .take(6)
          .toList(),
      'attendeeSummary': _attendeeSummary(names),
    });
  }

  @override
  Future<void> deleteMeeting({
    required String clubId,
    required String eventId,
  }) async {
    final ref = _eventRef(clubId, eventId);
    await _deleteRefs(await _attendanceRefs(ref));
    await ref.delete();
  }

  @override
  Future<List<ClubEvent>> loadMeetings({required String clubId}) async {
    return uniqueMeetings(
      await _mapDocs(_clubs.doc(clubId).collection('events'), _eventFrom),
    );
  }

  @override
  Stream<ClubEvent> watchEvent({
    required String clubId,
    required String eventId,
  }) {
    return _eventRef(
      clubId,
      eventId,
    ).snapshots().where((snap) => snap.exists).map(_eventFrom);
  }

  @override
  Stream<List<AttendanceRecord>> watchAttendance({
    required String clubId,
    required String eventId,
  }) {
    return _eventRef(clubId, eventId)
        .collection('attendance')
        .snapshots()
        .map((snap) => _sortedRecords(snap.docs.map(_recordFrom)));
  }

  @override
  Future<Map<String, List<AttendanceRecord>>> loadAttendanceRecords({
    required String clubId,
    required List<String> eventIds,
  }) async {
    final entries = await Future.wait(
      eventIds.map((id) async {
        final snap = await _eventRef(clubId, id).collection('attendance').get();
        return MapEntry(id, _sortedRecords(snap.docs.map(_recordFrom)));
      }),
    );
    return Map.fromEntries(entries);
  }

  @override
  Stream<QrSession?> watchAttendanceQr({
    required String clubId,
    required String eventId,
  }) {
    return _qrRef(clubId, eventId).snapshots().map((snap) {
      final data = snap.data();
      final token = data?['token'] as String?;
      final expiresAt = _date(data?['expiresAt']);
      if (token == null || token.isEmpty || expiresAt == null) return null;
      return QrSession(token: token, expiresAt: expiresAt);
    });
  }

  @override
  Future<QrSession> rotateAttendanceQr({
    required String clubId,
    required String eventId,
  }) async {
    final session = QrSession(
      token: generateAttendanceToken(),
      expiresAt: DateTime.now().add(attendanceQrLifetime),
    );
    final batch = _db.batch();
    batch.set(_qrRef(clubId, eventId), {
      'token': session.token,
      'expiresAt': Timestamp.fromDate(session.expiresAt),
    });
    batch.update(_eventRef(clubId, eventId), {'attendanceOpen': true});
    await batch.commit();
    return session;
  }

  @override
  Future<void> closeAttendance({
    required String clubId,
    required String eventId,
  }) async {
    final batch = _db.batch();
    batch.delete(_qrRef(clubId, eventId));
    batch.update(_eventRef(clubId, eventId), {'attendanceOpen': false});
    await batch.commit();
  }

  @override
  Future<CheckInResult> checkInWithQr({
    required String uid,
    required String raw,
  }) async {
    final payload = parseAttendanceQr(raw);
    if (payload == null) throw StateError('모아 출석 QR이 아니에요.');
    final clubId = payload.clubId;
    final eventRef = _eventRef(clubId, payload.eventId);
    final recordRef = eventRef.collection('attendance').doc(uid);

    final ClubEvent event;
    final String userName;
    try {
      final member = await _clubs
          .doc(clubId)
          .collection('members')
          .doc(uid)
          .get();
      if (!member.exists || member.data()?['status'] != 'active') {
        throw StateError('이 동아리의 구성원만 출석할 수 있어요.');
      }
      userName = (member.data()?['userName'] as String? ?? '').trim();
      final eventSnap = await eventRef.get();
      if (!eventSnap.exists) throw StateError('모임을 찾을 수 없어요.');
      event = _eventFrom(eventSnap);
      final existing = await recordRef.get();
      if (existing.exists) {
        return CheckInResult(
          clubId: clubId,
          event: event,
          record: _recordFrom(existing),
          duplicate: true,
        );
      }
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw StateError('이 동아리의 구성원만 출석할 수 있어요.');
      }
      rethrow;
    }
    if (!event.attendeeIds.contains(uid)) {
      throw StateError('이 모임의 참석 대상이 아니에요. 운영진에게 확인해 주세요.');
    }
    if (!event.attendanceOpen) throw StateError('출석이 마감된 모임이에요.');

    final batch = _db.batch();
    // 토큰은 본인만 쓰고 아무도 읽지 못하는 문서에 두고, 규칙이 현재 QR과 대조합니다.
    batch.set(eventRef.collection('proofs').doc(uid), {'token': payload.token});
    batch.set(recordRef, {
      'userId': uid,
      'userName': userName,
      'method': 'qr',
      'checkedAt': FieldValue.serverTimestamp(),
    });
    batch.update(eventRef, {'checkedInCount': FieldValue.increment(1)});
    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw StateError('QR이 만료되었거나 올바르지 않아요. 운영진 화면의 새 QR을 찍어 주세요.');
      }
      rethrow;
    }
    return CheckInResult(
      clubId: clubId,
      event: event,
      record: AttendanceRecord(
        userId: uid,
        userName: userName,
        method: AttendanceMethod.qr,
        checkedAt: kstNow(),
      ),
      duplicate: false,
    );
  }

  @override
  Future<void> markAttendanceManually({
    required String clubId,
    required String eventId,
    required String userId,
    required String userName,
    required String actorId,
    required String actorName,
    String? reason,
  }) async {
    final eventRef = _eventRef(clubId, eventId);
    final recordRef = eventRef.collection('attendance').doc(userId);
    if ((await recordRef.get()).exists) {
      throw StateError('이미 출석한 구성원이에요.');
    }
    final note = reason?.trim() ?? '';
    final batch = _db.batch();
    batch.set(recordRef, {
      'userId': userId,
      'userName': userName.trim(),
      'method': 'manual',
      'checkedAt': FieldValue.serverTimestamp(),
      'actorId': actorId,
      'actorName': actorName.trim(),
      if (note.isNotEmpty) 'reason': note,
    });
    batch.update(eventRef, {'checkedInCount': FieldValue.increment(1)});
    await batch.commit();
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

  Future<String> _uploadBytes(String path, ImagePayload image) async {
    final ref = _storage.ref(path);
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
      nickname: data['nickname'] as String?,
      primaryClubId: data['primaryClubId'] as String?,
    );
  }

  int _roleRank(String role) => switch (role) {
    'owner' => 0,
    'admin' => 1,
    _ => 2,
  };

  Future<void> _deleteRefs(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    for (var index = 0; index < refs.length; index += 400) {
      final batch = _db.batch();
      for (final ref in refs.skip(index).take(400)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
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

  DateTime? _kst(Object? value) {
    final date = _date(value);
    if (date == null) return null;
    return toKst(date);
  }

  ClubEvent _eventFrom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ClubEvent(
      id: doc.id,
      badge: data['badge'] as String? ?? '',
      title: data['title'] as String? ?? '',
      schedule: data['schedule'] as String? ?? '',
      artKicker: data['artKicker'] as String? ?? '',
      artTitle: data['artTitle'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      attendanceOpen: data['attendanceOpen'] as bool? ?? false,
      attendeeInitials: _strings(data['attendeeInitials']),
      attendeeSummary: data['attendeeSummary'] as String? ?? '',
      startsAt: _kst(data['startsAt']),
      endsAt: _kst(data['endsAt']),
      place: data['place'] as String? ?? '',
      status: data['status'] as String? ?? '',
      description: data['description'] as String? ?? '',
      supplies: data['supplies'] as String? ?? '',
      attendeeIds: _strings(data['attendeeIds']),
      checkedInCount: (data['checkedInCount'] as num?)?.toInt() ?? 0,
      feeAmount: (data['feeAmount'] as num?)?.toInt(),
      feeDueAt: _kst(data['feeDueAt']),
      feePaidCount: (data['feePaidCount'] as num?)?.toInt() ?? 0,
    );
  }

  DocumentReference<Map<String, dynamic>> _eventRef(
    String clubId,
    String eventId,
  ) => _clubs.doc(clubId).collection('events').doc(eventId);

  DocumentReference<Map<String, dynamic>> _qrRef(
    String clubId,
    String eventId,
  ) => _eventRef(clubId, eventId).collection('qr').doc('current');

  AttendanceRecord _recordFrom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AttendanceRecord(
      userId: data['userId'] as String? ?? doc.id,
      userName: data['userName'] as String? ?? '',
      method: data['method'] == 'manual'
          ? AttendanceMethod.manual
          : AttendanceMethod.qr,
      // 방금 쓴 기록은 서버 시각이 정해지기 전이라 지금 시각으로 보여 줍니다.
      checkedAt: _kst(data['checkedAt']) ?? kstNow(),
      reason: data['reason'] as String?,
      actorId: data['actorId'] as String?,
      actorName: data['actorName'] as String?,
    );
  }

  List<AttendanceRecord> _sortedRecords(Iterable<AttendanceRecord> records) {
    return records.toList()
      ..sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
  }

  /// 모임을 지울 때 함께 지울 출석 문서입니다.
  /// 출석 규칙이 아직 배포되지 않았거나 운영진이 아니면 읽을 수 없는데,
  /// 그렇다고 모임 삭제까지 막지는 않습니다.
  Future<List<DocumentReference<Map<String, dynamic>>>> _attendanceRefs(
    DocumentReference<Map<String, dynamic>> eventRef,
  ) async {
    final refs = <DocumentReference<Map<String, dynamic>>>[];
    for (final name in ['attendance', 'proofs', 'qr']) {
      try {
        final snap = await eventRef.collection(name).get();
        refs.addAll(snap.docs.map((doc) => doc.reference));
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied') rethrow;
      }
    }
    return refs;
  }

  Future<List<String>> _attendeeNames(String clubId, List<String> ids) async {
    if (ids.isEmpty) return const [];
    final snap = await _clubs.doc(clubId).collection('members').get();
    final names = <String, String>{};
    for (final doc in snap.docs) {
      final id = doc.data()['userId'] as String? ?? doc.id;
      names[id] = doc.data()['userName'] as String? ?? '';
    }
    return [for (final id in ids) names[id] ?? ''];
  }

  String _attendeeSummary(List<String> names) {
    final filled = names.where((name) => name.isNotEmpty).toList();
    if (filled.isEmpty) return '';
    if (filled.length <= 3) return '${filled.join(', ')} 참석';
    return '${filled.take(3).join(', ')} 외 ${filled.length - 3}명';
  }

  List<String> _strings(Object? value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    return const [];
  }
}
