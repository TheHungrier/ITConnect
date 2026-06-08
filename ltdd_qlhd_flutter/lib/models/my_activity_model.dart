import 'package:cloud_firestore/cloud_firestore.dart';

class MyActivityModel {
  final String registrationId;
  final String activityId;
  final String title;
  final String category;
  final String termId;
  final String academicYear;
  final String semester;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final String imageUrl;
  final String description;
  final String qrCode;
  final int points;
  final int penaltyPoints;
  final bool attended;
  final String status;
  final bool attendanceRejected;
  final String rejectReason;

  MyActivityModel({
    required this.registrationId,
    required this.activityId,
    required this.title,
    required this.category,
    required this.termId,
    required this.academicYear,
    required this.semester,
    required this.startAt,
    required this.endAt,
    required this.location,
    required this.imageUrl,
    required this.description,
    required this.qrCode,
    required this.points,
    required this.penaltyPoints,
    required this.attended,
    required this.status,
    required this.attendanceRejected,
    required this.rejectReason,
  });

  factory MyActivityModel.fromMyActivityData({
    required String registrationId,
    required Map<String, dynamic> data,
  }) {
    final activityId = data['activityId']?.toString() ?? '';
    final startAt = _toDateTime(data['startAt']);
    final endAt = _toDateTime(data['endAt'], fallback: startAt);

    return MyActivityModel(
      registrationId: data['registrationId']?.toString() ?? registrationId,
      activityId: activityId,
      title: data['title']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      termId: data['termId']?.toString() ?? '',
      academicYear:
          data['academicYear']?.toString() ??
          data['schoolYear']?.toString() ??
          '',
      semester: data['semester']?.toString() ?? '',
      startAt: startAt,
      endAt: endAt,
      location: data['location']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      qrCode: data['qrCode']?.toString() ?? activityId,
      points: _toInt(data['points']),
      penaltyPoints: _toInt(data['penaltyPoints']),
      attended: data['attended'] == true,
      status: data['status']?.toString() ?? 'upcoming',
      attendanceRejected: data['attendanceRejected'] == true,
      rejectReason: data['rejectReason']?.toString() ?? '',
    );
  }

  factory MyActivityModel.fromData({
    required String registrationId,
    required Map<String, dynamic> registrationData,
    required String activityId,
    required Map<String, dynamic> activityData,
  }) {
    final startAt = _toDateTime(
      activityData['startAt'] ?? registrationData['startAt'],
    );

    final endAt = _toDateTime(
      activityData['endAt'] ?? registrationData['endAt'],
      fallback: startAt,
    );

    return MyActivityModel(
      registrationId: registrationId,
      activityId: activityId,
      title:
          activityData['title']?.toString() ??
          registrationData['title']?.toString() ??
          '',
      category:
          activityData['category']?.toString() ??
          registrationData['category']?.toString() ??
          '',
      termId:
          activityData['termId']?.toString() ??
          registrationData['termId']?.toString() ??
          '',
      academicYear:
          activityData['academicYear']?.toString() ??
          registrationData['academicYear']?.toString() ??
          activityData['schoolYear']?.toString() ??
          registrationData['schoolYear']?.toString() ??
          '',
      semester:
          activityData['semester']?.toString() ??
          registrationData['semester']?.toString() ??
          '',
      startAt: startAt,
      endAt: endAt,
      location:
          activityData['location']?.toString() ??
          registrationData['location']?.toString() ??
          '',
      imageUrl:
          activityData['imageUrl']?.toString() ??
          registrationData['imageUrl']?.toString() ??
          '',
      description:
          activityData['description']?.toString() ??
          registrationData['description']?.toString() ??
          '',
      qrCode:
          activityData['qrCode']?.toString() ??
          registrationData['qrCode']?.toString() ??
          activityId,
      points: _toInt(registrationData['points'] ?? activityData['points']),
      penaltyPoints: _toInt(registrationData['penaltyPoints']),
      attended: registrationData['attended'] == true,
      status: registrationData['status']?.toString() ?? 'upcoming',
      attendanceRejected: registrationData['attendanceRejected'] == true,
      rejectReason: registrationData['rejectReason']?.toString() ?? '',
    );
  }

  static DateTime _toDateTime(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    }

    return fallback ?? DateTime.now();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
