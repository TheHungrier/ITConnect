import 'package:flutter/material.dart';

import '../models/admin_notification_model.dart';
import '../repositories/admin_notification_repository.dart';

class AdminNotificationController {
  final AdminNotificationRepository _repository;

  AdminNotificationController({AdminNotificationRepository? repository})
    : _repository = repository ?? AdminNotificationRepository();

  Stream<List<AdminNotificationModel>> watchNotifications() {
    return _repository.watchNotifications();
  }

  Stream<int> watchUnreadCount() {
    return _repository.watchUnreadCount();
  }

  Future<void> markOneRead(String notificationId) {
    return _repository.markOneRead(notificationId);
  }

  Future<void> markAllRead() {
    return _repository.markAllRead();
  }

  Color typeColor(String type) {
    switch (type) {
      case 'feedback':
        return Colors.deepPurple;
      case 'attendance':
        return Colors.orange;
      case 'activity':
        return Colors.blue;
      case 'warning':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  IconData typeIcon(String type) {
    switch (type) {
      case 'feedback':
        return Icons.feedback_rounded;
      case 'attendance':
        return Icons.qr_code_scanner_rounded;
      case 'activity':
        return Icons.event_note_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String typeLabel(String type) {
    switch (type) {
      case 'feedback':
        return 'Góp ý';
      case 'attendance':
        return 'Điểm danh';
      case 'activity':
        return 'Hoạt động';
      case 'warning':
        return 'Cảnh báo';
      default:
        return 'Thông báo';
    }
  }

  String formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    }

    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final year = time.year.toString();

    return '$day/$month/$year';
  }
}
