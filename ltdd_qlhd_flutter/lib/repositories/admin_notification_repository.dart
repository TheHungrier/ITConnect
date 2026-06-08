import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_notification_model.dart';

class AdminNotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _db.collection('adminNotifications');
  }

  Stream<List<AdminNotificationModel>> watchNotifications() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => AdminNotificationModel.fromDoc(doc))
          .toList();
    });
  }

  Stream<int> watchUnreadCount() {
    return _collection.where('isRead', isEqualTo: false).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.length;
    });
  }

  Future<void> markOneRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;

    await _collection.doc(notificationId).set({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markAllRead() async {
    final snapshot = await _collection.where('isRead', isEqualTo: false).get();

    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> createNotification({
    required String title,
    required String message,
    String type = 'general',
    String relatedId = '',
  }) async {
    await _collection.add({
      'title': title.trim(),
      'message': message.trim(),
      'type': type.trim(),
      'relatedId': relatedId.trim(),
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
