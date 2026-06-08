import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'app_theme_controller.dart';

class ProfilePasswordResult {
  final bool success;
  final String message;

  ProfilePasswordResult({required this.success, required this.message});
}

class ProfileUpdateResult {
  final bool success;
  final String message;

  ProfileUpdateResult({required this.success, required this.message});
}

class ProfileController {
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel?> getCurrentUserData() {
    return _userRepository.getCurrentUserData();
  }

  String get currentEmail {
    return _auth.currentUser?.email ?? '';
  }

  String safeString(dynamic user, String field) {
    if (user == null) {
      return '';
    }

    try {
      switch (field) {
        case 'id':
          return user.id ?? '';

        case 'name':
          return user.name ?? '';

        case 'email':
          return user.email ?? '';

        case 'role':
          return user.role ?? '';

        case 'studentId':
          return user.studentId ?? '';

        case 'studentCode':
          return user.studentId ?? '';

        case 'phone':
          return user.phone ?? '';

        case 'faculty':
          return user.faculty ?? '';

        case 'className':
          return user.className ?? '';

        case 'class':
          return user.className ?? '';

        case 'avatar':
          return user.avatar ?? '';

        case 'avatarUrl':
          return user.avatar ?? '';

        default:
          return '';
      }
    } catch (_) {
      return '';
    }
  }

  bool notificationEnabled(dynamic user) {
    try {
      return user?.notificationEnabled != false;
    } catch (_) {
      return true;
    }
  }

  bool isDarkMode() {
    return AppThemeController.isDarkMode;
  }

  Future<ProfileUpdateResult> updateDarkMode(bool value) async {
    try {
      await AppThemeController.setDarkMode(value);

      return ProfileUpdateResult(
        success: true,
        message: value ? 'Đã bật chế độ tối' : 'Đã bật chế độ sáng',
      );
    } catch (_) {
      return ProfileUpdateResult(
        success: false,
        message: 'Không thể cập nhật chế độ giao diện',
      );
    }
  }

  String getInitial(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return 'S';
    }

    return trimmedName[0].toUpperCase();
  }

  Future<ProfileUpdateResult> updateNotificationEnabled(bool value) async {
    try {
      await _userRepository.updateNotificationEnabled(value);

      return ProfileUpdateResult(
        success: true,
        message: value ? 'Đã bật thông báo' : 'Đã tắt thông báo',
      );
    } catch (_) {
      return ProfileUpdateResult(
        success: false,
        message: 'Không thể cập nhật trạng thái thông báo',
      );
    }
  }

  Future<ProfilePasswordResult> sendResetPasswordEmail(String email) async {
    if (email.trim().isEmpty || email == 'Chưa cập nhật') {
      return ProfilePasswordResult(
        success: false,
        message: 'Không tìm thấy email để gửi yêu cầu đổi mật khẩu',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      return ProfilePasswordResult(
        success: true,
        message: 'Đã gửi email đặt lại mật khẩu',
      );
    } catch (_) {
      return ProfilePasswordResult(
        success: false,
        message: 'Không thể gửi email đặt lại mật khẩu',
      );
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
