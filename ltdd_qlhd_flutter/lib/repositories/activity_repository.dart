import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ltdd_qlhd_flutter/services/reminder_service.dart';

import '../models/activity_model.dart';

class ActivityRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<ActivityModel>> getLatestActivities() {
    return _db
        .collection('activities')
        .orderBy('startAt', descending: false)
        .limit(12)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) {
                final data = doc.data();
                return data['status'] != 'cancelled' &&
                    data['isDeleted'] != true;
              })
              .take(6)
              .map((doc) => ActivityModel.fromFirestore(doc))
              .toList();
        });
  }

  Stream<List<ActivityModel>> getAllActivities() {
    return _db
        .collection('activities')
        .orderBy('startAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) {
                final data = doc.data();
                return data['status'] != 'cancelled' &&
                    data['isDeleted'] != true;
              })
              .map((doc) => ActivityModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<bool> isRegistered(String activityId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

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

  Stream<bool> watchRegistered(String activityId) {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(false);
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('myActivities')
        .doc(activityId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return false;

          final data = doc.data() ?? {};
          return data['status'] != 'cancelled';
        });
  }

  Stream<Map<String, dynamic>?> watchMyRegistration(String activityId) {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(null);
    }

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('myActivities')
        .doc(activityId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;

          final data = doc.data() ?? {};
          final status = data['status']?.toString() ?? '';

          if (status == 'cancelled') return null;

          return data;
        });
  }

  Future<void> registerActivity(ActivityModel activity) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để đăng ký hoạt động');
    }

    final activityRef = _db.collection('activities').doc(activity.id);
    final userRef = _db.collection('users').doc(user.uid);
    final myActivityRef = userRef.collection('myActivities').doc(activity.id);

    final nearFullNotificationRef = _db
        .collection('adminNotifications')
        .doc('activity_near_full_${activity.id}');

    await _db.runTransaction((transaction) async {
      final activitySnapshot = await transaction.get(activityRef);
      final myActivitySnapshot = await transaction.get(myActivityRef);
      final nearFullNotificationSnapshot = await transaction.get(
        nearFullNotificationRef,
      );

      if (!activitySnapshot.exists) {
        throw Exception('Hoạt động không tồn tại');
      }

      final data = activitySnapshot.data() as Map<String, dynamic>;

      if (data['status'] == 'cancelled' || data['isDeleted'] == true) {
        throw Exception('Hoạt động này đã bị hủy, không thể đăng ký');
      }

      if (data['registrationOpen'] == false) {
        throw Exception('Hoạt động chưa mở đăng ký');
      }

      final currentParticipants = _toInt(data['currentParticipants']);
      final maxParticipants = _toInt(data['maxParticipants']);
      final points = _toInt(data['points']);

      final startAt = _toDateTime(data['startAt']);
      final endAt = _toDateTime(data['endAt'], fallback: startAt);

      final termId = data['termId']?.toString().trim().isNotEmpty == true
          ? data['termId'].toString().trim()
          : activity.termId;

      final academicYear = data['academicYear']?.toString().trim() ?? '';
      final semester = data['semester']?.toString().trim() ?? '';

      if (termId.trim().isEmpty) {
        throw Exception('Hoạt động chưa được gán học kỳ');
      }

      if (DateTime.now().isAfter(endAt)) {
        throw Exception('Hoạt động đã kết thúc, không thể đăng ký');
      }

      if (myActivitySnapshot.exists) {
        final myData = myActivitySnapshot.data() as Map<String, dynamic>;
        final status = myData['status']?.toString() ?? 'upcoming';

        if (status != 'cancelled') {
          throw Exception('Bạn đã đăng ký hoạt động này rồi');
        }
      }

      final qrCode = data['qrCode']?.toString().trim().isNotEmpty == true
          ? data['qrCode'].toString().trim()
          : activity.id;

      if (maxParticipants > 0 && currentParticipants >= maxParticipants) {
        throw Exception('Hoạt động đã đủ số lượng đăng ký');
      }

      final newParticipants = currentParticipants + 1;

      transaction.update(activityRef, {
        'currentParticipants': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(userRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(myActivityRef, {
        'registrationId': activity.id,
        'activityId': activity.id,
        'termId': termId,
        'academicYear': academicYear,
        'semester': semester,
        'points': points,
        'attended': false,
        'status': 'upcoming',
        'registeredAt': FieldValue.serverTimestamp(),
        'cancelledAt': null,
        'cancelReason': null,
        'title': activity.title,
        'category': activity.category,
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'location': activity.location,
        'imageUrl': activity.imageUrl,
        'description': activity.description,
        'qrCode': qrCode,
      }, SetOptions(merge: true));

      _createNearFullNotificationIfNeeded(
        transaction: transaction,
        notificationRef: nearFullNotificationRef,
        notificationExists: nearFullNotificationSnapshot.exists,
        activityId: activity.id,
        activityTitle: activity.title,
        currentParticipants: newParticipants,
        maxParticipants: maxParticipants,
      );
    });

    try {
      await ReminderService.instance.scheduleActivityReminderFromActivity(
        activity,
      );
    } catch (_) {}
  }

  Future<void> cancelRegistration(ActivityModel activity) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để hủy đăng ký');
    }

    final activityRef = _db.collection('activities').doc(activity.id);
    final userRef = _db.collection('users').doc(user.uid);
    final myActivityRef = userRef.collection('myActivities').doc(activity.id);

    await _db.runTransaction((transaction) async {
      final activitySnapshot = await transaction.get(activityRef);
      final myActivitySnapshot = await transaction.get(myActivityRef);

      if (!activitySnapshot.exists) {
        throw Exception('Hoạt động không tồn tại');
      }

      if (!myActivitySnapshot.exists) {
        throw Exception('Bạn chưa đăng ký hoạt động này');
      }

      final activityData = activitySnapshot.data() as Map<String, dynamic>;
      final myActivityData = myActivitySnapshot.data() as Map<String, dynamic>;

      final status = myActivityData['status']?.toString() ?? 'upcoming';
      final attended = myActivityData['attended'] == true;
      final attendanceRejected = myActivityData['attendanceRejected'] == true;

      final currentParticipants = _toInt(activityData['currentParticipants']);
      final startAt = _toDateTime(activityData['startAt']);
      final endAt = _toDateTime(activityData['endAt'], fallback: startAt);
      final attendanceFinalized = activityData['attendanceFinalized'] == true;

      final now = DateTime.now();

      if (status == 'cancelled') {
        throw Exception('Bạn đã hủy đăng ký hoạt động này rồi');
      }

      if (status == 'absent') {
        throw Exception('Bạn đã bị đánh dấu vắng, không thể hủy đăng ký');
      }

      if (attendanceRejected) {
        throw Exception('Điểm danh đã bị từ chối, không thể hủy đăng ký');
      }

      if (attended) {
        throw Exception('Bạn đã điểm danh nên không thể hủy đăng ký');
      }

      if (status == 'completed') {
        throw Exception('Hoạt động đã hoàn thành, không thể hủy đăng ký');
      }

      if (attendanceFinalized) {
        throw Exception('Hoạt động đã chốt điểm danh, không thể hủy đăng ký');
      }

      if (!now.isBefore(startAt)) {
        throw Exception('Hoạt động đã bắt đầu, không thể hủy đăng ký');
      }

      if (!now.isBefore(endAt)) {
        throw Exception('Hoạt động đã kết thúc, không thể hủy đăng ký');
      }

      if (currentParticipants > 0) {
        transaction.update(activityRef, {
          'currentParticipants': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(userRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.delete(myActivityRef);
    });

    try {
      await ReminderService.instance.cancelActivityReminder(activity.id);
    } catch (_) {}
  }

  void _createNearFullNotificationIfNeeded({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> notificationRef,
    required bool notificationExists,
    required String activityId,
    required String activityTitle,
    required int currentParticipants,
    required int maxParticipants,
  }) {
    if (notificationExists) return;
    if (maxParticipants <= 0) return;

    final percent = currentParticipants / maxParticipants;

    if (percent < 0.9) return;

    transaction.set(notificationRef, {
      'title': 'Hoạt động gần đầy số lượng',
      'message':
          'Hoạt động "$activityTitle" đã đạt $currentParticipants/$maxParticipants sinh viên đăng ký.',
      'type': 'activity',
      'isRead': false,
      'relatedId': activityId,
      'dedupeKey': 'activity_near_full_$activityId',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _toDateTime(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    }

    return fallback ?? DateTime.now();
  }
}
