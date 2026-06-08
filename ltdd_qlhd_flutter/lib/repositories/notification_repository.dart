import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _db.collection('notifications');
  }

  Stream<List<NotificationModel>> getNotifications() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _collection.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) {
            return NotificationModel.fromFirestore(
              doc,
              currentUserId: user.uid,
            );
          })
          .where((notification) {
            final targetUserId = notification.targetUserId.trim();

            return targetUserId.isEmpty || targetUserId == user.uid;
          })
          .toList();
    });
  }

  Future<void> markOneRead(String notificationId) async {
    final user = _auth.currentUser;

    if (user == null) return;
    if (notificationId.trim().isEmpty) return;

    await _collection.doc(notificationId).set({
      'readBy': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllRead(List<NotificationModel> notifications) async {
    final user = _auth.currentUser;

    if (user == null) return;

    final unreadNotifications = notifications.where((n) => !n.isRead).toList();

    if (unreadNotifications.isEmpty) return;

    final batch = _db.batch();

    for (final notification in unreadNotifications) {
      final ref = _collection.doc(notification.id);

      batch.set(ref, {
        'readBy': FieldValue.arrayUnion([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> createActivityNotification({
    required String activityId,
    required String activityTitle,
    required String activityCategory,
    required DateTime activityDate,
    required String activityTime,
  }) async {
    await _collection.add({
      'title': 'Hoạt động mới',
      'body':
          '$activityTitle vừa được mở đăng ký. Hãy xem và đăng ký nếu bạn quan tâm.',
      'type': 'activity',
      'targetUserId': '',
      'readBy': <String>[],
      'activityId': activityId,
      'activityTitle': activityTitle,
      'activityCategory': activityCategory,
      'activityDate': Timestamp.fromDate(activityDate),
      'activityTime': activityTime,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createImportantNewsNotification({
    required String newsId,
    required String newsTitle,
    required String summary,
  }) async {
    await _collection.add({
      'title': 'Tin tức quan trọng',
      'body': summary.trim().isNotEmpty
          ? summary.trim()
          : '$newsTitle vừa được đăng trên ITConnect.',
      'type': 'news',
      'targetUserId': '',
      'readBy': <String>[],
      'newsId': newsId,
      'newsTitle': newsTitle,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createReminderNotification({
    required String activityId,
    required String activityTitle,
    required String message,
  }) async {
    await _collection.add({
      'title': 'Nhắc nhở hoạt động',
      'body': message.trim().isNotEmpty
          ? message.trim()
          : 'Hoạt động "$activityTitle" sắp diễn ra.',
      'type': 'reminder',
      'targetUserId': '',
      'readBy': <String>[],
      'activityId': activityId,
      'activityTitle': activityTitle,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createWarningNotification({
    required String title,
    required String body,
    String activityId = '',
  }) async {
    await _collection.add({
      'title': title.trim().isNotEmpty ? title.trim() : 'Thông báo',
      'body': body.trim(),
      'type': 'warning',
      'targetUserId': '',
      'readBy': <String>[],
      'activityId': activityId.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createAttendanceRejectedNotification({
    required String targetUserId,
    required String activityId,
    required String activityTitle,
    required String reason,
  }) async {
    final safeReason = reason.trim().isEmpty
        ? 'Minh chứng điểm danh không hợp lệ.'
        : reason.trim();

    await _collection.add({
      'title': 'Điểm danh bị từ chối',
      'body':
          'Điểm danh của bạn trong hoạt động "$activityTitle" đã bị từ chối. Lý do: $safeReason',
      'type': 'attendance_rejected',
      'targetUserId': targetUserId.trim(),
      'readBy': <String>[],
      'activityId': activityId.trim(),
      'activityTitle': activityTitle.trim(),
      'rejectReason': safeReason,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
