import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationController extends ChangeNotifier {
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  String? _lastNewestNotificationId;

  Stream<List<NotificationModel>> getNotifications() {
    return _notificationRepository.getNotifications();
  }

  int unreadCount(List<NotificationModel> notifications) {
    return notifications.where((notification) {
      return notification.isRead == false;
    }).length;
  }

  Future<void> markAllRead(List<NotificationModel> notifications) async {
    await _notificationRepository.markAllRead(notifications);
  }

  Future<void> markOneRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationRepository.markOneRead(notification.id);
    }
  }

  void checkNewNotificationSound(List<NotificationModel> notifications) {
    if (notifications.isEmpty) return;

    final newestNotification = notifications.first;
    final isUnread = newestNotification.isRead == false;

    if (_lastNewestNotificationId == null) {
      _lastNewestNotificationId = newestNotification.id;
      return;
    }

    if (newestNotification.id != _lastNewestNotificationId && isUnread) {
      _lastNewestNotificationId = newestNotification.id;
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Color typeColor(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF2E7D32);

      case 'reminder':
        return const Color(0xFF1565C0);

      case 'warning':
        return const Color(0xFFE65100);

      case 'new':
        return const Color(0xFF6A1B9A);

      case 'news':
        return const Color(0xFF00897B);

      case 'attendance_rejected':
        return const Color(0xFFD32F2F);

      default:
        return const Color(0xFF607D8B);
    }
  }

  IconData typeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_rounded;

      case 'reminder':
        return Icons.alarm_rounded;

      case 'warning':
        return Icons.warning_amber_rounded;

      case 'new':
        return Icons.campaign_rounded;

      case 'news':
        return Icons.article_rounded;

      case 'attendance_rejected':
        return Icons.block_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  String typeLabel(String type) {
    switch (type) {
      case 'success':
        return 'Thành công';

      case 'reminder':
        return 'Nhắc nhở';

      case 'warning':
        return 'Cảnh báo';

      case 'new':
        return 'Hoạt động mới';

      case 'news':
        return 'Tin tức';

      case 'attendance_rejected':
        return 'Từ chối điểm danh';

      default:
        return 'Thông báo';
    }
  }

  String formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    }

    if (difference.inDays == 1) {
      return 'Hôm qua';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  Future<void> refresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
