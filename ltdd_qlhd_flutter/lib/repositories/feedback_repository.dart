import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendFeedback({
    required String type,
    required String content,
    required String userName,
    required String studentId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để gửi góp ý');
    }

    final safeType = type.trim();
    final safeContent = content.trim();
    final safeUserName = userName.trim().isEmpty
        ? 'Sinh viên'
        : userName.trim();
    final safeStudentId = studentId.trim();

    if (safeContent.isEmpty) {
      throw Exception('Nội dung góp ý không được để trống');
    }

    final feedbackRef = _db.collection('feedbacks').doc();
    final notificationRef = _db.collection('adminNotifications').doc();

    final batch = _db.batch();

    batch.set(feedbackRef, {
      'userId': user.uid,
      'userEmail': user.email ?? '',
      'userName': safeUserName,
      'studentId': safeStudentId,
      'type': safeType,
      'content': safeContent,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(notificationRef, {
      'title': 'Có góp ý mới',
      'message': _buildAdminNotificationMessage(
        userName: safeUserName,
        studentId: safeStudentId,
        type: safeType,
      ),
      'type': 'feedback',
      'isRead': false,
      'relatedId': feedbackRef.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getFeedbacksForAdmin() {
    return _db
        .collection('feedbacks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _buildAdminNotificationMessage({
    required String userName,
    required String studentId,
    required String type,
  }) {
    final studentText = studentId.trim().isEmpty ? '' : ' ($studentId)';

    return '$userName$studentText vừa gửi góp ý về "$type".';
  }
}
