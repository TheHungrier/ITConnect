import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckInPreviewData {
  final String activityId;
  final String qrCode;
  final String activityTitle;
  final String activityLocation;
  final String activityTime;
  final String studentName;
  final String studentCode;

  CheckInPreviewData({
    required this.activityId,
    required this.qrCode,
    required this.activityTitle,
    required this.activityLocation,
    required this.activityTime,
    required this.studentName,
    required this.studentCode,
  });
}

class CheckInRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> hasRegisteredActivity(String activityId) async {
    final user = _auth.currentUser;

    if (user == null) return false;

    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('myActivities')
        .doc(activityId)
        .get();

    if (!doc.exists) return false;

    final data = doc.data() ?? {};
    return data['status'] != 'cancelled';
  }

  Future<bool> hasCheckedIn(String activityId) async {
    final user = _auth.currentUser;

    if (user == null) return false;

    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('myActivities')
        .doc(activityId)
        .get();

    if (!doc.exists) return false;

    final data = doc.data() ?? {};
    final status = data['status']?.toString() ?? '';

    return data['attended'] == true ||
        status == 'completed' ||
        status == 'pending_review';
  }

  Future<CheckInPreviewData> validateQrBeforeOpenDetail({
    required String activityId,
    required String qrCode,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để điểm danh');
    }

    final safeActivityId = activityId.trim();
    final safeQrCode = qrCode.trim();

    if (safeActivityId.isEmpty) {
      throw Exception('Mã hoạt động không hợp lệ');
    }

    if (safeQrCode.isEmpty) {
      throw Exception('Mã QR không hợp lệ');
    }

    final activityRef = _db.collection('activities').doc(safeActivityId);
    final userRef = _db.collection('users').doc(user.uid);
    final myActivityRef = userRef
        .collection('myActivities')
        .doc(safeActivityId);

    final activitySnapshot = await activityRef.get();
    final userSnapshot = await userRef.get();
    final myActivitySnapshot = await myActivityRef.get();

    if (!activitySnapshot.exists) {
      throw Exception('Hoạt động không tồn tại');
    }

    if (!myActivitySnapshot.exists) {
      throw Exception('Bạn chưa đăng ký hoạt động này');
    }

    final activityData = activitySnapshot.data() ?? {};
    final userData = userSnapshot.data() ?? {};
    final myActivityData = myActivitySnapshot.data() ?? {};

    final status = myActivityData['status']?.toString() ?? 'upcoming';
    final attended = myActivityData['attended'] == true;

    if (status == 'cancelled') {
      throw Exception('Bạn đã hủy đăng ký hoạt động này');
    }

    if (status == 'absent') {
      throw Exception('Hoạt động này đã bị đánh dấu vắng');
    }

    if (status == 'pending_review') {
      throw Exception('Minh chứng điểm danh của bạn đang chờ admin xử lý');
    }

    if (attended || status == 'completed') {
      throw Exception('Bạn đã điểm danh hoạt động này rồi');
    }

    if (activityData['attendanceFinalized'] == true) {
      throw Exception('Hoạt động đã chốt điểm danh');
    }

    if (activityData['isCheckInOpen'] != true) {
      throw Exception('Hoạt động chưa mở điểm danh');
    }

    final activityQrCode =
        activityData['qrCode']?.toString().trim().isNotEmpty == true
        ? activityData['qrCode'].toString().trim()
        : safeActivityId;

    if (activityQrCode != safeQrCode) {
      throw Exception('Mã QR không đúng với hoạt động này');
    }

    final startAt = activityData['startAt'] is Timestamp
        ? (activityData['startAt'] as Timestamp).toDate()
        : null;

    final endAt = activityData['endAt'] is Timestamp
        ? (activityData['endAt'] as Timestamp).toDate()
        : null;

    return CheckInPreviewData(
      activityId: safeActivityId,
      qrCode: safeQrCode,
      activityTitle: activityData['title']?.toString() ?? 'Hoạt động sinh viên',
      activityLocation: activityData['location']?.toString() ?? 'Chưa cập nhật',
      activityTime: startAt != null && endAt != null
          ? '${_formatDate(startAt)} ${_formatTime(startAt)} - ${_formatTime(endAt)}'
          : 'Chưa cập nhật',
      studentName: userData['name']?.toString() ?? 'Sinh viên',
      studentCode: userData['studentId']?.toString() ?? 'Chưa cập nhật',
    );
  }

  Future<void> confirmCheckIn({
    required String activityId,
    required String qrCode,
    required String qrRawValue,
    required String proofUrl,
    required String proofType,
    String? note,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để điểm danh');
    }

    final safeActivityId = activityId.trim();
    final safeQrCode = qrCode.trim();
    final safeProofUrl = proofUrl.trim();
    final safeProofType = proofType.trim().isEmpty ? 'image' : proofType.trim();

    if (safeActivityId.isEmpty) {
      throw Exception('Mã hoạt động không hợp lệ');
    }

    if (safeQrCode.isEmpty) {
      throw Exception('Mã QR không hợp lệ');
    }

    if (safeProofUrl.isEmpty) {
      throw Exception('Chưa có minh chứng điểm danh');
    }

    final activityRef = _db.collection('activities').doc(safeActivityId);
    final userRef = _db.collection('users').doc(user.uid);
    final myActivityRef = userRef
        .collection('myActivities')
        .doc(safeActivityId);
    final checkInRef = _db.collection('checkIns').doc();

    await _db.runTransaction((transaction) async {
      final activitySnapshot = await transaction.get(activityRef);
      final myActivitySnapshot = await transaction.get(myActivityRef);

      if (!activitySnapshot.exists) {
        throw Exception('Hoạt động không tồn tại');
      }

      if (!myActivitySnapshot.exists) {
        throw Exception('Bạn chưa đăng ký hoạt động này');
      }

      final activityData = activitySnapshot.data() ?? {};
      final myActivityData = myActivitySnapshot.data() ?? {};

      final status = myActivityData['status']?.toString() ?? 'upcoming';
      final attended = myActivityData['attended'] == true;

      if (status == 'cancelled') {
        throw Exception('Bạn đã hủy đăng ký hoạt động này');
      }

      if (status == 'absent') {
        throw Exception('Hoạt động này đã bị đánh dấu vắng');
      }

      if (status == 'pending_review') {
        throw Exception('Minh chứng điểm danh của bạn đang chờ admin xử lý');
      }

      if (attended || status == 'completed') {
        throw Exception('Bạn đã điểm danh hoạt động này rồi');
      }

      if (activityData['attendanceFinalized'] == true) {
        throw Exception('Hoạt động đã chốt điểm danh');
      }

      if (activityData['isCheckInOpen'] != true) {
        throw Exception('Hoạt động chưa mở điểm danh');
      }

      final activityQrCode =
          activityData['qrCode']?.toString().trim().isNotEmpty == true
          ? activityData['qrCode'].toString().trim()
          : safeActivityId;

      if (activityQrCode != safeQrCode) {
        throw Exception('Mã QR không đúng với hoạt động này');
      }

      transaction.set(checkInRef, {
        'userId': user.uid,
        'activityId': safeActivityId,
        'qrCode': safeQrCode,
        'qrRawValue': qrRawValue,
        'checkInTime': FieldValue.serverTimestamp(),
        'status': 'pending_review',
        'proofUrl': safeProofUrl,
        'proofType': safeProofType,
        'proofUploadedAt': FieldValue.serverTimestamp(),
        'note': note ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(userRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.update(myActivityRef, {
        'attended': false,
        'status': 'pending_review',
        'checkedInAt': FieldValue.serverTimestamp(),
        'proofUrl': safeProofUrl,
        'proofType': safeProofType,
        'proofUploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
