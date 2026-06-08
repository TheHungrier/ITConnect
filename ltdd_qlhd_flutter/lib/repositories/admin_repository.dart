import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_dashboard_stats.dart';

class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AdminDashboardStats> watchDashboardStats() async* {
    while (true) {
      yield await getDashboardStats();
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<AdminDashboardStats> getDashboardStats() async {
    final usersSnapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final activitiesSnapshot = await _db.collection('activities').get();

    final feedbackSnapshot = await _db
        .collection('feedbacks')
        .where('status', isEqualTo: 'pending')
        .get();

    final myActivitiesSnapshot = await _db
        .collectionGroup('myActivities')
        .get();

    await _syncEndedActivityNotifications(
      activitiesSnapshot: activitiesSnapshot,
      myActivitiesSnapshot: myActivitiesSnapshot,
    );

    int openActivities = 0;

    for (final doc in activitiesSnapshot.docs) {
      final data = doc.data();

      if (data['registrationOpen'] == true) {
        openActivities++;
      }
    }

    int attendedCount = 0;
    int absentCount = 0;

    for (final doc in myActivitiesSnapshot.docs) {
      final data = doc.data();

      final bool attended = data['attended'] == true;
      final String status = data['status']?.toString() ?? '';

      if (attended || status == 'completed') {
        attendedCount++;
      }

      if (status == 'absent') {
        absentCount++;
      }
    }

    final recentActivities =
        activitiesSnapshot.docs
            .map((doc) => AdminRecentActivity.fromDoc(doc))
            .toList()
          ..sort((a, b) => b.startAt.compareTo(a.startAt));

    return AdminDashboardStats(
      totalStudents: usersSnapshot.docs.length,
      totalActivities: activitiesSnapshot.docs.length,
      openActivities: openActivities,
      totalRegistrations: myActivitiesSnapshot.docs.length,
      attendedCount: attendedCount,
      absentCount: absentCount,
      pendingFeedbacks: feedbackSnapshot.docs.length,
      recentActivities: recentActivities.take(4).toList(),
    );
  }

  Future<void> _syncEndedActivityNotifications({
    required QuerySnapshot<Map<String, dynamic>> activitiesSnapshot,
    required QuerySnapshot<Map<String, dynamic>> myActivitiesSnapshot,
  }) async {
    final now = DateTime.now();

    for (final activityDoc in activitiesSnapshot.docs) {
      final activityId = activityDoc.id;
      final activityData = activityDoc.data();

      final title = activityData['title']?.toString().trim().isNotEmpty == true
          ? activityData['title'].toString().trim()
          : 'Hoạt động';

      final endAt = _toDateTime(activityData['endAt']);
      final attendanceFinalized = activityData['attendanceFinalized'] == true;

      if (attendanceFinalized) continue;
      if (now.isBefore(endAt)) continue;

      final relatedRegistrations = myActivitiesSnapshot.docs.where((doc) {
        final data = doc.data();
        final registeredActivityId = data['activityId']?.toString() ?? '';
        final status = data['status']?.toString() ?? '';

        return registeredActivityId == activityId && status != 'cancelled';
      }).toList();

      if (relatedRegistrations.isEmpty) continue;

      int attendedCount = 0;
      int absentCount = 0;

      for (final registrationDoc in relatedRegistrations) {
        final data = registrationDoc.data();

        final attended = data['attended'] == true;
        final status = data['status']?.toString() ?? '';

        if (attended || status == 'completed') {
          attendedCount++;
        }

        if (status == 'absent') {
          absentCount++;
        }
      }

      final waitingCount =
          relatedRegistrations.length - attendedCount - absentCount;

      if (waitingCount <= 0) continue;

      final notificationId = 'activity_ended_$activityId';

      final notificationRef = _db
          .collection('adminNotifications')
          .doc(notificationId);

      final notificationSnapshot = await notificationRef.get();

      if (notificationSnapshot.exists) continue;

      await notificationRef.set({
        'title': 'Hoạt động đã kết thúc',
        'message':
            'Hoạt động "$title" đã kết thúc. Có $attendedCount/${relatedRegistrations.length} sinh viên đã điểm danh, còn $waitingCount sinh viên chưa được chốt.',
        'type': 'attendance',
        'isRead': false,
        'relatedId': activityId,
        'dedupeKey': notificationId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
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
