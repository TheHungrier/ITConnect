import 'package:flutter/material.dart';

import '../repositories/feedback_repository.dart';
import '../repositories/user_repository.dart';

class FeedbackSubmitResult {
  final bool success;
  final String message;

  FeedbackSubmitResult({required this.success, required this.message});
}

class FeedbackController extends ChangeNotifier {
  final FeedbackRepository _feedbackRepository = FeedbackRepository();
  final UserRepository _userRepository = UserRepository();

  bool isSubmitting = false;

  final List<String> feedbackTypes = const [
    'Lỗi hệ thống',
    'Hoạt động',
    'Điểm danh',
    'Tài khoản',
    'Giao diện',
    'Khác',
  ];

  Future<FeedbackSubmitResult> submitFeedback({
    required String type,
    required String content,
  }) async {
    final safeContent = content.trim();

    if (safeContent.isEmpty) {
      return FeedbackSubmitResult(
        success: false,
        message: 'Vui lòng nhập nội dung góp ý',
      );
    }

    if (safeContent.length < 10) {
      return FeedbackSubmitResult(
        success: false,
        message: 'Nội dung góp ý nên có ít nhất 10 ký tự',
      );
    }

    try {
      isSubmitting = true;
      notifyListeners();

      final user = await _userRepository.getCurrentUserData();

      await _feedbackRepository.sendFeedback(
        type: type,
        content: safeContent,
        userName: user?.name ?? 'Sinh viên',
        studentId: user?.studentId ?? '',
      );

      return FeedbackSubmitResult(
        success: true,
        message: 'Đã gửi góp ý thành công',
      );
    } catch (e) {
      return FeedbackSubmitResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
