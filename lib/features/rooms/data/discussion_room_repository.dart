import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'discussion_room.dart';

class DiscussionRoomRepository {
  DiscussionRoomRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _firestore.collection('profiles').doc(uid);

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw const DiscussionRoomException(
        'Sign in before creating or joining a discussion room.',
      );
    }
    return user.uid;
  }

  Future<void> _ensureProfile(User user) async {
    final profileRef = _profile(user.uid);
    final snapshot = await profileRef.get();
    final existingName = snapshot.data()?['displayName'] as String?;
    if (snapshot.exists && (existingName?.trim().isNotEmpty ?? false)) {
      return;
    }

    final authName = user.displayName?.trim() ?? '';
    final emailName = user.email?.split('@').first.trim() ?? '';
    final chosenName = authName.length >= 2
        ? authName
        : (emailName.length >= 2 ? emailName : 'Member');
    final displayName = chosenName.length > 24
        ? chosenName.substring(0, 24)
        : chosenName;

    await profileRef.set({
      'displayName': displayName,
      'createdAt': snapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<DiscussionRoom>> watchOpenRooms() {
    // Only show rooms created through the current general-purpose flow.
    // Older seeded demo rooms used subject-specific topic values and must not
    // appear as real user meetings (for example, Number Theory sample rooms).
    return _rooms
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(DiscussionRoom.fromFirestore)
            .where((room) => room.isJoinable && room.topic == 'General')
            .toList());
  }

  Future<String> createRoom({
    required String title,
    required String topic,
    required String description,
  }) async {
    final user = _auth.currentUser;
    final uid = _uid;
    if (title.trim().isEmpty) {
      throw const DiscussionRoomException('Enter a room name.');
    }

    // Older accounts may not have a Firestore profile document yet.
    // Create/repair that owner-only profile before the room transaction.
    await _ensureProfile(user!);

    final roomRef = _rooms.doc();
    final memberRef = roomRef.collection('members').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final profileSnapshot = await transaction.get(_profile(uid));
      final profile = profileSnapshot.data();
      if (profile == null) {
        throw const DiscussionRoomException(
          'Your profile could not be found. Please sign out and sign in again.',
        );
      }

      final displayName = profile['displayName'] as String? ?? 'Member';
      final now = FieldValue.serverTimestamp();
      transaction.set(roomRef, {
        'title': title.trim(),
        'topic': topic,
        'description': description.trim(),
        'hostUid': uid,
        'hostName': displayName,
        'participantCount': 1,
        'status': 'open',
        'createdAt': now,
        'updatedAt': now,
      });
      transaction.set(memberRef, {
        'uid': uid,
        'displayName': displayName,
        'joinedAt': now,
      });
    });

    return roomRef.id;
  }

  Future<void> joinRoom(String roomId) async {
    final uid = _uid;
    final roomRef = _rooms.doc(roomId);
    final memberRef = roomRef.collection('members').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      final memberSnapshot = await transaction.get(memberRef);
      final profileSnapshot = await transaction.get(_profile(uid));

      if (!roomSnapshot.exists) {
        throw const DiscussionRoomException('This room no longer exists.');
      }
      if (memberSnapshot.exists) return;

      final room = roomSnapshot.data()!;
      final profile = profileSnapshot.data();
      if (profile == null) {
        throw const DiscussionRoomException(
          'Complete your profile before joining a room.',
        );
      }

      if (room['status'] != 'open') {
        throw const DiscussionRoomException('This room is closed.');
      }

      transaction.set(memberRef, {
        'uid': uid,
        'displayName': profile['displayName'] as String? ?? 'Member',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(roomRef, {
        'participantCount': (room['participantCount'] as int? ?? 0) + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> leaveRoom(String roomId) async {
    final uid = _uid;
    final roomRef = _rooms.doc(roomId);
    final memberRef = roomRef.collection('members').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      final memberSnapshot = await transaction.get(memberRef);
      if (!roomSnapshot.exists || !memberSnapshot.exists) return;

      final room = roomSnapshot.data()!;
      final count = room['participantCount'] as int? ?? 1;
      transaction.delete(memberRef);
      transaction.update(roomRef, {
        'participantCount': count > 0 ? count - 1 : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

class DiscussionRoomException implements Exception {
  const DiscussionRoomException(this.message);

  final String message;

  @override
  String toString() => message;
}
