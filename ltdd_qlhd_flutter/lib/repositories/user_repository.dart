import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    await _ensureCurrentUserDocument();

    final doc = await _users.doc(user.uid).get();

    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> watchCurrentUserData() async* {
    final user = _auth.currentUser;

    if (user == null) {
      yield null;
      return;
    }

    await _ensureCurrentUserDocument();

    yield* _users.doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<UserModel?> getUserByLoginId(String loginId) async {
    final value = loginId.trim();

    if (value.isEmpty) return null;

    final loginIdQuery = await _users
        .where('loginId', isEqualTo: value)
        .limit(1)
        .get();

    if (loginIdQuery.docs.isNotEmpty) {
      return UserModel.fromFirestore(loginIdQuery.docs.first);
    }

    final studentIdQuery = await _users
        .where('studentId', isEqualTo: value)
        .limit(1)
        .get();

    if (studentIdQuery.docs.isNotEmpty) {
      return UserModel.fromFirestore(studentIdQuery.docs.first);
    }

    final studentCodeQuery = await _users
        .where('studentCode', isEqualTo: value)
        .limit(1)
        .get();

    if (studentCodeQuery.docs.isNotEmpty) {
      return UserModel.fromFirestore(studentCodeQuery.docs.first);
    }

    return null;
  }

  Future<UserModel?> getUserByStudentId(String studentId) async {
    return getUserByLoginId(studentId);
  }

  Future<void> createOrUpdateCurrentUser({
    required String name,
    required String email,
    required String role,
    required String loginId,
    String studentId = '',
    String phone = '',
    String faculty = '',
    String className = '',
    String avatar = '',
    int points = 0,
    bool notificationEnabled = true,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để cập nhật thông tin người dùng');
    }

    await _users.doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role.trim(),
      'loginId': loginId.trim(),
      'studentId': studentId.trim(),
      'phone': phone.trim(),
      'faculty': faculty.trim(),
      'className': className.trim(),
      'avatar': avatar.trim(),
      'points': points,
      'notificationEnabled': notificationEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateNotificationEnabled(bool value) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để cập nhật thông báo');
    }

    await _ensureCurrentUserDocument();

    await _users.doc(user.uid).set({
      'notificationEnabled': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> syncUserToUidDocument(UserModel oldUser) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để đồng bộ thông tin người dùng');
    }

    await _users.doc(user.uid).set({
      'name': oldUser.name,
      'email': oldUser.email,
      'role': oldUser.role,
      'loginId': oldUser.loginId.isNotEmpty
          ? oldUser.loginId
          : oldUser.studentId,
      'studentId': oldUser.studentId,
      'phone': oldUser.phone,
      'faculty': oldUser.faculty,
      'className': oldUser.className,
      'avatar': oldUser.avatar,
      'points': oldUser.points,
      'notificationEnabled': oldUser.notificationEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _ensureCurrentUserDocument() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final userRef = _users.doc(user.uid);
    final uidDoc = await userRef.get();

    if (uidDoc.exists && _hasMainUserData(uidDoc.data())) {
      return;
    }

    final oldDoc = await _findUserDocByEmail(user.email);

    if (oldDoc == null) {
      if (!uidDoc.exists) {
        await userRef.set({
          'name': '',
          'email': user.email ?? '',
          'role': 'student',
          'loginId': '',
          'studentId': '',
          'phone': '',
          'faculty': '',
          'className': '',
          'avatar': '',
          'points': 0,
          'notificationEnabled': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return;
    }

    final oldData = oldDoc.data();
    final uidData = uidDoc.data();

    final normalized = _normalizeUserData(
      oldData: oldData,
      authEmail: user.email ?? '',
      currentNotificationEnabled: uidData?['notificationEnabled'],
    );

    await userRef.set(normalized, SetOptions(merge: true));
  }

  Map<String, dynamic> _normalizeUserData({
    required Map<String, dynamic> oldData,
    required String authEmail,
    required dynamic currentNotificationEnabled,
  }) {
    final studentId =
        oldData['studentId']?.toString() ??
        oldData['studentCode']?.toString() ??
        '';

    final loginId = oldData['loginId']?.toString() ?? studentId;

    return {
      'name': oldData['name']?.toString() ?? '',
      'email': oldData['email']?.toString() ?? authEmail,
      'role': oldData['role']?.toString() ?? 'student',
      'loginId': loginId,
      'studentId': studentId,
      'phone': oldData['phone']?.toString() ?? '',
      'faculty': oldData['faculty']?.toString() ?? '',
      'className':
          oldData['className']?.toString() ??
          oldData['class']?.toString() ??
          '',
      'avatar':
          oldData['avatar']?.toString() ??
          oldData['avatarUrl']?.toString() ??
          '',
      'points': _toInt(oldData['points']),
      'notificationEnabled':
          currentNotificationEnabled ?? oldData['notificationEnabled'] ?? true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findUserDocByEmail(
    String? email,
  ) async {
    final safeEmail = email?.trim() ?? '';

    if (safeEmail.isEmpty) return null;

    final query = await _users
        .where('email', isEqualTo: safeEmail)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return query.docs.first;
  }

  bool _hasMainUserData(Map<String, dynamic>? data) {
    if (data == null) return false;

    final name = data['name']?.toString().trim() ?? '';

    final loginId =
        data['loginId']?.toString().trim() ??
        data['studentId']?.toString().trim() ??
        data['studentCode']?.toString().trim() ??
        '';

    return name.isNotEmpty && loginId.isNotEmpty;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
