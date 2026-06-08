import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

class LoginResult {
  final bool success;
  final String? error;
  final UserModel? user;

  LoginResult({required this.success, this.error, this.user});
}

class ResetPasswordResult {
  final bool success;
  final String message;

  ResetPasswordResult({required this.success, required this.message});
}

class LoginController {
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();

  static const String _rememberKey = 'remember_student_login';
  static const String _savedLoginIdKey = 'saved_login_id';
  static const String _savedAvatarUrlKey = 'saved_avatar_url';

  Future<String> loadSavedLoginId() async {
    final prefs = await SharedPreferences.getInstance();

    final remember = prefs.getBool(_rememberKey) ?? false;
    final savedLoginId = prefs.getString(_savedLoginIdKey) ?? '';

    if (remember && savedLoginId.isNotEmpty) {
      return savedLoginId;
    }

    return '';
  }

  Future<String> loadSavedAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();

    final remember = prefs.getBool(_rememberKey) ?? false;
    final savedAvatarUrl = prefs.getString(_savedAvatarUrlKey) ?? '';

    if (remember && savedAvatarUrl.isNotEmpty) {
      return savedAvatarUrl;
    }

    return '';
  }

  Future<bool> isRememberedLoginId(String loginId) async {
    final prefs = await SharedPreferences.getInstance();

    final remember = prefs.getBool(_rememberKey) ?? false;
    final savedLoginId = prefs.getString(_savedLoginIdKey) ?? '';

    return remember && savedLoginId == loginId.trim();
  }

  Future<void> saveLoginInfo({
    required String loginId,
    required String avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_rememberKey, true);
    await prefs.setString(_savedLoginIdKey, loginId.trim());
    await prefs.setString(_savedAvatarUrlKey, avatarUrl.trim());
  }

  Future<void> clearSavedLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_rememberKey, false);
    await prefs.remove(_savedLoginIdKey);
    await prefs.remove(_savedAvatarUrlKey);
  }

  Future<LoginResult> login({
    required String loginId,
    required String password,
  }) async {
    if (loginId.trim().isEmpty || password.trim().isEmpty) {
      return LoginResult(
        success: false,
        error: 'Vui lòng nhập mã đăng nhập và mật khẩu',
      );
    }

    try {
      final userModel = await _userRepository.getUserByLoginId(loginId.trim());

      if (userModel == null) {
        return LoginResult(success: false, error: 'Mã đăng nhập không tồn tại');
      }

      if (userModel.email.isEmpty) {
        return LoginResult(
          success: false,
          error: 'Tài khoản này chưa có email đăng nhập',
        );
      }

      await _authRepository.loginWithEmailAndPassword(
        email: userModel.email,
        password: password.trim(),
      );

      final currentUser = await _userRepository.getCurrentUserData();

      return LoginResult(success: true, user: currentUser ?? userModel);
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng nhập thất bại';

      if (e.code == 'wrong-password') {
        message = 'Sai mật khẩu';
      } else if (e.code == 'invalid-credential') {
        message = 'Mã đăng nhập hoặc mật khẩu không đúng';
      } else if (e.code == 'user-not-found') {
        message = 'Tài khoản chưa được tạo trong Firebase Auth';
      } else if (e.code == 'too-many-requests') {
        message = 'Bạn thử quá nhiều lần. Vui lòng thử lại sau';
      }

      return LoginResult(success: false, error: message);
    } catch (_) {
      return LoginResult(
        success: false,
        error: 'Có lỗi xảy ra. Vui lòng thử lại',
      );
    }
  }

  Future<ResetPasswordResult> sendResetPasswordByLoginId(String loginId) async {
    if (loginId.trim().isEmpty) {
      return ResetPasswordResult(
        success: false,
        message: 'Vui lòng nhập mã đăng nhập',
      );
    }

    try {
      final userModel = await _userRepository.getUserByLoginId(loginId.trim());

      if (userModel == null) {
        return ResetPasswordResult(
          success: false,
          message: 'Mã đăng nhập không tồn tại',
        );
      }

      if (userModel.email.isEmpty) {
        return ResetPasswordResult(
          success: false,
          message: 'Tài khoản này chưa có email khôi phục',
        );
      }

      await _authRepository
          .sendResetPasswordEmail(userModel.email)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('timeout');
            },
          );

      return ResetPasswordResult(
        success: true,
        message:
            'Đã gửi email đặt lại mật khẩu đến ${userModel.email}. Vui lòng kiểm tra hộp thư.',
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Không thể gửi email khôi phục mật khẩu';

      if (e.code == 'invalid-email') {
        message = 'Email khôi phục không hợp lệ';
      } else if (e.code == 'user-not-found') {
        message = 'Email này chưa được đăng ký Firebase';
      } else if (e.code == 'too-many-requests') {
        message = 'Bạn thao tác quá nhiều lần. Vui lòng thử lại sau';
      }

      return ResetPasswordResult(success: false, message: message);
    } catch (_) {
      return ResetPasswordResult(
        success: false,
        message:
            'Không thể gửi email khôi phục. Nếu dùng emulator, hãy thử thiết bị thật hoặc emulator có Google Play.',
      );
    }
  }

  Future<String> loadSavedStudentId() => loadSavedLoginId();

  Future<bool> isRememberedStudent(String studentId) {
    return isRememberedLoginId(studentId);
  }

  Future<void> saveStudentInfo({
    required String studentId,
    required String avatarUrl,
  }) {
    return saveLoginInfo(loginId: studentId, avatarUrl: avatarUrl);
  }

  Future<ResetPasswordResult> sendResetPasswordByStudentId(String studentId) {
    return sendResetPasswordByLoginId(studentId);
  }
}
