import 'package:flutter/material.dart';

import '../models/my_activity_model.dart';
import '../repositories/my_activity_repository.dart';
import '../services/reminder_service.dart';

class ReminderActionResult {
  final bool success;
  final String message;

  ReminderActionResult({required this.success, required this.message});
}

class ReminderController extends ChangeNotifier {
  final MyActivityRepository _myActivityRepository = MyActivityRepository();
  final ReminderService _reminderService = ReminderService.instance;

  bool isLoading = true;
  bool isReminderEnabled = true;
  int minutesBefore = 60;

  final List<int> reminderOptions = const [15, 30, 60, 1440];

  Stream<List<MyActivityModel>> getMyActivities() {
    return _myActivityRepository.getMyActivities();
  }

  Future<void> loadSettings() async {
    isLoading = true;
    notifyListeners();

    isReminderEnabled = await _reminderService.isReminderEnabled();
    minutesBefore = await _reminderService.getMinutesBefore();

    isLoading = false;
    notifyListeners();
  }

  Future<ReminderActionResult> setReminderEnabled(
    bool value,
    List<MyActivityModel> activities,
  ) async {
    try {
      if (value) {
        final granted = await _reminderService.requestPermission();

        if (!granted) {
          return ReminderActionResult(
            success: false,
            message: 'Bạn chưa cấp quyền thông báo cho ứng dụng',
          );
        }
      }

      isReminderEnabled = value;
      notifyListeners();

      await _reminderService.setReminderEnabled(value);

      if (value) {
        await syncReminders(activities);
      }

      return ReminderActionResult(
        success: true,
        message: value ? 'Đã bật nhắc nhở hoạt động' : 'Đã tắt nhắc nhở',
      );
    } catch (e) {
      return ReminderActionResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<ReminderActionResult> changeMinutesBefore(
    int minutes,
    List<MyActivityModel> activities,
  ) async {
    try {
      minutesBefore = minutes;
      notifyListeners();

      await _reminderService.setMinutesBefore(minutes);

      if (isReminderEnabled) {
        await syncReminders(activities);
      }

      return ReminderActionResult(
        success: true,
        message: 'Đã cập nhật thời gian nhắc nhở',
      );
    } catch (e) {
      return ReminderActionResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<ReminderActionResult> syncReminders(
    List<MyActivityModel> activities,
  ) async {
    try {
      final upcomingActivities = filterUpcomingActivities(activities);

      await _reminderService.scheduleAllMyActivityReminders(upcomingActivities);

      return ReminderActionResult(
        success: true,
        message: 'Đã đồng bộ nhắc nhở hoạt động',
      );
    } catch (e) {
      return ReminderActionResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<ReminderActionResult> scheduleOne(MyActivityModel activity) async {
    try {
      if (!isReminderEnabled) {
        return ReminderActionResult(
          success: false,
          message: 'Bạn cần bật nhắc nhở trước',
        );
      }

      await _reminderService.scheduleMyActivityReminder(
        activity,
        minutesBefore: minutesBefore,
      );

      return ReminderActionResult(
        success: true,
        message: 'Đã tạo nhắc nhở cho hoạt động',
      );
    } catch (e) {
      return ReminderActionResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<ReminderActionResult> cancelOne(MyActivityModel activity) async {
    try {
      await _reminderService.cancelActivityReminder(activity.activityId);

      return ReminderActionResult(
        success: true,
        message: 'Đã hủy nhắc nhở của hoạt động',
      );
    } catch (e) {
      return ReminderActionResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  List<MyActivityModel> filterUpcomingActivities(
    List<MyActivityModel> activities,
  ) {
    final now = DateTime.now();

    return activities.where((activity) {
      if (activity.status != 'upcoming') return false;
      if (activity.attended) return false;
      if (activity.startAt.isBefore(now)) return false;

      return true;
    }).toList();
  }

  DateTime reminderTime(MyActivityModel activity) {
    return activity.startAt.subtract(Duration(minutes: minutesBefore));
  }

  String reminderOptionText(int minutes) {
    if (minutes == 15) return '15 phút';
    if (minutes == 30) return '30 phút';
    if (minutes == 60) return '1 giờ';
    if (minutes == 1440) return '1 ngày';

    return '$minutes phút';
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
