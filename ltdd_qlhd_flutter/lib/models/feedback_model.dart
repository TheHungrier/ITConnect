import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String studentId;
  final String type;
  final String content;
  final String status;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.studentId,
    required this.type,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  factory FeedbackModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return FeedbackModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      studentId: data['studentId']?.toString() ?? '',
      type: data['type']?.toString() ?? 'Khác',
      content: data['content']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'studentId': studentId,
      'type': type,
      'content': content,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }
}
