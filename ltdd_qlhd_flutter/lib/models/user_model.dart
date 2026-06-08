import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String loginId;
  final String studentId;
  final String phone;
  final String faculty;
  final String className;
  final int points;
  final String avatar;
  final bool notificationEnabled;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.loginId,
    required this.studentId,
    required this.phone,
    required this.faculty,
    required this.className,
    required this.points,
    required this.avatar,
    required this.notificationEnabled,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final oldStudentId =
        data['studentId']?.toString() ?? data['studentCode']?.toString() ?? '';

    return UserModel(
      id: doc.id,
      name: data['name']?.toString() ?? 'Sinh viên',
      email: data['email']?.toString() ?? '',
      role: data['role']?.toString() ?? 'student',

      loginId: data['loginId']?.toString() ?? oldStudentId,

      studentId: oldStudentId,

      phone: data['phone']?.toString() ?? '',
      faculty: data['faculty']?.toString() ?? '',
      className:
          data['className']?.toString() ?? data['class']?.toString() ?? '',
      points: _toInt(data['points']),
      avatar: data['avatar']?.toString() ?? data['avatarUrl']?.toString() ?? '',
      notificationEnabled: data['notificationEnabled'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'loginId': loginId,
      'studentId': studentId,
      'phone': phone,
      'faculty': faculty,
      'className': className,
      'points': points,
      'avatar': avatar,
      'notificationEnabled': notificationEnabled,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
