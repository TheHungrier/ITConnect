import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String relatedId;
  final DateTime createdAt;

  const AdminNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.relatedId,
    required this.createdAt,
  });

  factory AdminNotificationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return AdminNotificationModel(
      id: doc.id,
      title: data['title']?.toString() ?? 'Thông báo',
      message: data['message']?.toString() ?? '',
      type: data['type']?.toString() ?? 'general',
      isRead: data['isRead'] == true,
      relatedId: data['relatedId']?.toString() ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }
}
