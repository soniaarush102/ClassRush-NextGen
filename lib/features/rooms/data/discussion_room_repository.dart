import 'dart:ui' show Offset;
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
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map(DiscussionRoom.fromFirestore)
              .where((room) => room.isJoinable && room.topic == 'General')
              .toList();
          // Sort locally so this query needs only Firestore's automatic
          // single-field index and does not depend on a composite index.
          rooms.sort((a, b) {
            final aDate = a.createdAt;
            final bDate = b.createdAt;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });
          return rooms;
        });
  }

  /// Streams the current members of a room so every participant sees
  /// joins and departures without refreshing the meeting screen.
  Stream<List<Map<String, dynamic>>> watchParticipants(String roomId) {
    return _rooms.doc(roomId).collection('members').snapshots().map((snapshot) {
      final participants =
          snapshot.docs.map((document) => document.data()).toList();
      participants.sort((a, b) {
        final aJoined = a['joinedAt'];
        final bJoined = b['joinedAt'];
        if (aJoined is Timestamp && bJoined is Timestamp) {
          return aJoined.compareTo(bJoined);
        }
        return 0;
      });
      return participants;
    });
  }


  /// Streams saved whiteboard strokes. Firestore snapshots keep every
  /// participant's board in sync as new strokes are added.
  Stream<List<Map<String, dynamic>>> watchBoardStrokes(String roomId) {
    return _rooms.doc(roomId).collection('boardStrokes').snapshots().map((snapshot) {
      final strokes = snapshot.docs.map((document) {
        return <String, dynamic>{...document.data(), 'id': document.id};
      }).toList();
      strokes.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime is Timestamp && bTime is Timestamp) {
          return aTime.compareTo(bTime);
        }
        return 0;
      });
      return strokes;
    });
  }

  Future<void> addBoardStroke(
    String roomId,
    List<Offset> points, {
    required int color,
    required double width,
  }) async {
    final uid = _uid;
    final strokeRef = _rooms.doc(roomId).collection('boardStrokes').doc();

    // Firestore rules cap a stroke at 2,000 points. Touch devices can emit
    // many pointer events during one long drag, so evenly sample long strokes
    // while preserving their first and last points.
    const maxStoredPoints = 1800;
    final storedPoints = points.length <= maxStoredPoints
        ? points
        : List<Offset>.generate(
            maxStoredPoints,
            (index) => points[
              (index * (points.length - 1) / (maxStoredPoints - 1)).round()
            ],
          );

    await strokeRef.set({
      'uid': uid,
      'points': storedPoints.map((point) => [point.dx, point.dy]).toList(),
      'color': color,
      'width': width,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> deleteBoardStroke(String roomId, String strokeId) async {
    await _rooms.doc(roomId).collection('boardStrokes').doc(strokeId).delete();
  }

  Future<void> clearBoard(String roomId) async {
    final strokes = await _rooms.doc(roomId).collection('boardStrokes').get();
    for (var start = 0; start < strokes.docs.length; start += 450) {
      final batch = _firestore.batch();
      for (final document in strokes.docs.skip(start).take(450)) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
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
