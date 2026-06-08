import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRecentActivity {
  final String id;
  final String title;
  final String category;
  final String location;
  final DateTime startAt;
  final int currentParticipants;
  final int maxParticipants;

  const AdminRecentActivity({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.startAt,
    required this.currentParticipants,
    required this.maxParticipants,
  });

  factory AdminRecentActivity.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return AdminRecentActivity(
      id: doc.id,
      title: data['title']?.toString() ?? 'Hoạt động',
      category: data['category']?.toString() ?? 'Khác',
      location: data['location']?.toString() ?? '',
      startAt: parseDate(data['startAt']),
      currentParticipants: parseInt(data['currentParticipants']),
      maxParticipants: parseInt(data['maxParticipants']),
    );
  }
}

class AdminDashboardStats {
  final int totalStudents;
  final int totalActivities;
  final int openActivities;
  final int totalRegistrations;
  final int attendedCount;
  final int absentCount;
  final int pendingFeedbacks;
  final List<AdminRecentActivity> recentActivities;

  const AdminDashboardStats({
    required this.totalStudents,
    required this.totalActivities,
    required this.openActivities,
    required this.totalRegistrations,
    required this.attendedCount,
    required this.absentCount,
    required this.pendingFeedbacks,
    required this.recentActivities,
  });

  double get attendanceRate {
    if (totalRegistrations == 0) return 0;
    return attendedCount / totalRegistrations;
  }

  int get attendancePercent {
    return (attendanceRate * 100).round();
  }

  int get waitingAttendanceCount {
    final waiting = totalRegistrations - attendedCount - absentCount;
    return waiting < 0 ? 0 : waiting;
  }
}
