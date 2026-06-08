import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String title;
  final String category;
  final String termId;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final String imageUrl;
  final String description;
  final int currentParticipants;
  final int maxParticipants;
  final int points;
  final String qrCode;
  final bool isCheckInOpen;

  ActivityModel({
    required this.id,
    required this.title,
    required this.category,
    required this.termId,
    required this.startAt,
    required this.endAt,
    required this.location,
    required this.imageUrl,
    required this.description,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.points,
    required this.qrCode,
    required this.isCheckInOpen,
  });

  factory ActivityModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return ActivityModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      termId: data['termId']?.toString() ?? '',
      startAt: _toDateTime(data['startAt']),
      endAt: _toDateTime(data['endAt']),
      location: data['location']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      currentParticipants: _toInt(data['currentParticipants']),
      maxParticipants: _toInt(data['maxParticipants']),
      points: _toInt(data['points']),
      qrCode: data['qrCode']?.toString() ?? doc.id,
      isCheckInOpen: data['isCheckInOpen'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'termId': termId,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'location': location,
      'imageUrl': imageUrl,
      'description': description,
      'currentParticipants': currentParticipants,
      'maxParticipants': maxParticipants,
      'points': points,
      'qrCode': qrCode,
      'isCheckInOpen': isCheckInOpen,
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
