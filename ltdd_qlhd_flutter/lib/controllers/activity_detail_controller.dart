import 'package:flutter/material.dart';

import '../models/activity_model.dart';
import '../repositories/activity_repository.dart';

class ActivityRegisterResult {
  final bool success;
  final String message;

  ActivityRegisterResult({required this.success, required this.message});
}

class ActivityDetailController extends ChangeNotifier {
  final ActivityRepository _activityRepository = ActivityRepository();

  bool isLoading = false;

  Stream<bool> watchRegistered(String activityId) {
    return _activityRepository.watchRegistered(activityId);
  }

  Stream<Map<String, dynamic>?> watchMyRegistration(String activityId) {
    return _activityRepository.watchMyRegistration(activityId);
  }

  double getRegisterPercent(ActivityModel activity) {
    if (activity.maxParticipants == 0) {
      return 0.0;
    }

    return (activity.currentParticipants / activity.maxParticipants).clamp(
      0.0,
      1.0,
    );
  }

  bool isFull(ActivityModel activity) {
    if (activity.maxParticipants == 0) {
      return false;
    }

    return activity.currentParticipants >= activity.maxParticipants;
  }

  bool canCancelRegistration({
    required ActivityModel activity,
    required Map<String, dynamic>? registrationData,
  }) {
    if (registrationData == null) return false;

    final status = registrationData['status']?.toString() ?? 'upcoming';
    final attended = registrationData['attended'] == true;
    final attendanceRejected = registrationData['attendanceRejected'] == true;

    final now = DateTime.now();

    if (status == 'cancelled') return false;
    if (status == 'completed') return false;
    if (status == 'absent') return false;
    if (attended) return false;
    if (attendanceRejected) return false;

    if (!now.isBefore(activity.startAt)) {
      return false;
    }

    return true;
  }

  String getRegistrationMessage({
    required ActivityModel activity,
    required Map<String, dynamic>? registrationData,
  }) {
    if (registrationData == null) {
      return '';
    }

    final status = registrationData['status']?.toString() ?? 'upcoming';
    final attended = registrationData['attended'] == true;
    final attendanceRejected = registrationData['attendanceRejected'] == true;
    final rejectReason = registrationData['rejectReason']?.toString() ?? '';

    final now = DateTime.now();

    if (status == 'absent') {
      if (attendanceRejected) {
        return rejectReason.trim().isNotEmpty
            ? 'Điểm danh bị từ chối: $rejectReason'
            : 'Bạn bị đánh dấu vắng do minh chứng không hợp lệ';
      }

      return 'Bạn bị đánh dấu vắng hoạt động này';
    }

    if (attendanceRejected) {
      return rejectReason.trim().isNotEmpty
          ? 'Điểm danh bị từ chối: $rejectReason'
          : 'Điểm danh của bạn đã bị từ chối';
    }

    if (attended || status == 'completed') {
      return 'Bạn đã điểm danh hoạt động này';
    }

    if (!now.isBefore(activity.endAt)) {
      return 'Hoạt động đã kết thúc, không thể hủy đăng ký';
    }

    if (!now.isBefore(activity.startAt)) {
      return 'Hoạt động đã bắt đầu, không thể hủy đăng ký';
    }

    return 'Bạn đã đăng ký hoạt động này';
  }

  Future<ActivityRegisterResult> registerActivity(
    ActivityModel activity,
  ) async {
    try {
      isLoading = true;
      notifyListeners();

      await _activityRepository.registerActivity(activity);

      return ActivityRegisterResult(
        success: true,
        message: 'Đăng ký hoạt động thành công',
      );
    } catch (e) {
      return ActivityRegisterResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ActivityRegisterResult> cancelRegistration(
    ActivityModel activity,
  ) async {
    try {
      isLoading = true;
      notifyListeners();

      await _activityRepository.cancelRegistration(activity);

      return ActivityRegisterResult(
        success: true,
        message: 'Đã hủy đăng ký hoạt động',
      );
    } catch (e) {
      return ActivityRegisterResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
