import 'package:cloud_firestore/cloud_firestore.dart';

class DiscussionRoom {
  const DiscussionRoom({
    required this.id,
    required this.title,
    required this.topic,
    required this.description,
    required this.hostUid,
    required this.hostName,
    required this.ageBand,
    required this.participantCount,
    required this.maxParticipants,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String topic;
  final String description;
  final String hostUid;
  final String hostName;
  final String ageBand;
  final int participantCount;
  final int maxParticipants;
  final String status;
  final DateTime? createdAt;

  bool get isJoinable =>
      status == 'open' && participantCount < maxParticipants;

  factory DiscussionRoom.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    final timestamp = data['createdAt'];
    return DiscussionRoom(
      id: snapshot.id,
      title: data['title'] as String? ?? '',
      topic: data['topic'] as String? ?? '',
      description: data['description'] as String? ?? '',
      hostUid: data['hostUid'] as String? ?? '',
      hostName: data['hostName'] as String? ?? 'Student',
      ageBand: data['ageBand'] as String? ?? '',
      participantCount: data['participantCount'] as int? ?? 0,
      maxParticipants: data['maxParticipants'] as int? ?? 8,
      status: data['status'] as String? ?? 'closed',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
