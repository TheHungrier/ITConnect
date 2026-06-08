import '../models/activity_model.dart';
import '../models/news_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../repositories/activity_repository.dart';
import '../repositories/news_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/user_repository.dart';

class HomeController {
  final UserRepository _userRepository = UserRepository();
  final NewsRepository _newsRepository = NewsRepository();
  final ActivityRepository _activityRepository = ActivityRepository();
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  Future<UserModel?> getCurrentUserData() {
    return _userRepository.getCurrentUserData();
  }

  Stream<List<NewsModel>> getLatestNews() {
    return _newsRepository.getLatestNews();
  }

  Stream<List<ActivityModel>> getLatestActivities() {
    return _activityRepository.getLatestActivities();
  }

  Stream<List<NotificationModel>> getNotifications() {
    return _notificationRepository.getNotifications();
  }

  int getUnreadNotificationCount(List<NotificationModel> notifications) {
    return notifications.where((notification) {
      return notification.isRead == false;
    }).length;
  }

  bool hasUnreadNotification(List<NotificationModel> notifications) {
    return getUnreadNotificationCount(notifications) > 0;
  }

  String getShortName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return '${parts[parts.length - 2]} ${parts[parts.length - 1]}';
    }

    return fullName;
  }

  String getAvatarUrl(UserModel? user) {
    if (user == null) return '';

    return user.avatar.trim();
  }

  double getActivityPercent(ActivityModel activity) {
    if (activity.maxParticipants == 0) {
      return 0.0;
    }

    return (activity.currentParticipants / activity.maxParticipants)
        .clamp(0.0, 1.0);
  }
}