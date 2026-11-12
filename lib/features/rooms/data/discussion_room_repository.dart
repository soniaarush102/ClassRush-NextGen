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

  Stream<List<DiscussionRoom>> watchOpenRooms({String? topic}) {
    Query<Map<String, dynamic>> query = _rooms
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true);

    if (topic != null && topic != 'All topics') {
      query = query.where('topic', isEqualTo: topic);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(DiscussionRoom.fromFirestore)
              .where((room) => room.isJoinable)
              .toList(),
        );
  }

  Future<String> createRoom({
    required String title,
    required String topic,
    required String description,
  }) async {
    final uid = _uid;
    if (title.trim().isEmpty) {
      throw const DiscussionRoomException('Enter a room name.');
    }

    final roomRef = _rooms.doc();
    final memberRef = roomRef.collection('members').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final profileSnapshot = await transaction.get(_profile(uid));
      final profile = profileSnapshot.data();
      if (profile == null) {
        throw const DiscussionRoomException(
          'Complete your student profile before creating a room.',
        );
      }

      final displayName = profile['displayName'] as String? ?? 'Student';
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
          'Complete your student profile before joining a room.',
        );
      }

      if (room['status'] != 'open') {
        throw const DiscussionRoomException('This room is closed.');
      }

      transaction.set(memberRef, {
        'uid': uid,
        'displayName': profile['displayName'] as String? ?? 'Student',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(roomRef, {
        'participantCount':
            (room['participantCount'] as int? ?? 0) + 1,
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
