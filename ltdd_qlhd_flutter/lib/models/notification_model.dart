import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  final String targetUserId;

  final String activityId;
  final String activityTitle;
  final String activityCategory;
  final DateTime? activityDate;
  final String activityTime;

  final String newsId;
  final String newsTitle;

  final String rejectReason;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.targetUserId,
    required this.activityId,
    required this.activityTitle,
    required this.activityCategory,
    required this.activityDate,
    required this.activityTime,
    required this.newsId,
    required this.newsTitle,
    required this.rejectReason,
  });

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String currentUserId = '',
  }) {
    final data = doc.data() ?? {};

    final readByRaw = data['readBy'];
    final readBy = readByRaw is List
        ? readByRaw.map((e) => e.toString()).toList()
        : <String>[];

    final bool isReadByCurrentUser = currentUserId.isNotEmpty
        ? readBy.contains(currentUserId)
        : data['isRead'] == true;

    return NotificationModel(
      id: doc.id,
      title: data['title']?.toString() ?? 'Thông báo',
      body: data['body']?.toString() ?? '',
      type: data['type']?.toString() ?? 'default',
      isRead: isReadByCurrentUser,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      targetUserId: data['targetUserId']?.toString() ?? '',
      activityId: data['activityId']?.toString() ?? '',
      activityTitle: data['activityTitle']?.toString() ?? '',
      activityCategory: data['activityCategory']?.toString() ?? '',
      activityDate: data['activityDate'] is Timestamp
          ? (data['activityDate'] as Timestamp).toDate()
          : null,
      activityTime: data['activityTime']?.toString() ?? '',
      newsId: data['newsId']?.toString() ?? '',
      newsTitle: data['newsTitle']?.toString() ?? '',
      rejectReason: data['rejectReason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'targetUserId': targetUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'activityId': activityId,
      'activityTitle': activityTitle,
      'activityCategory': activityCategory,
      'activityDate': activityDate != null
          ? Timestamp.fromDate(activityDate!)
          : null,
      'activityTime': activityTime,
      'newsId': newsId,
      'newsTitle': newsTitle,
      'rejectReason': rejectReason,
    };
  }
}
