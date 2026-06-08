import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInModel {
  final String id;
  final String userId;
  final String activityId;
  final String qrCode;
  final String qrRawValue;
  final DateTime checkInTime;
  final String status;
  final String proofUrl;
  final String note;

  CheckInModel({
    required this.id,
    required this.userId,
    required this.activityId,
    required this.qrCode,
    required this.qrRawValue,
    required this.checkInTime,
    required this.status,
    required this.proofUrl,
    required this.note,
  });

  factory CheckInModel.fromMap(Map<String, dynamic> data, String docId) {
    return CheckInModel(
      id: docId,
      userId: data['userId']?.toString() ?? '',
      activityId: data['activityId']?.toString() ?? '',
      qrCode: data['qrCode']?.toString() ?? '',
      qrRawValue: data['qrRawValue']?.toString() ?? '',
      checkInTime: _toDateTime(data['checkInTime']),
      status: data['status']?.toString() ?? 'pending',
      proofUrl: data['proofUrl']?.toString() ?? '',
      note: data['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'activityId': activityId,
      'qrCode': qrCode,
      'qrRawValue': qrRawValue,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'status': status,
      'proofUrl': proofUrl,
      'note': note,
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }
}
