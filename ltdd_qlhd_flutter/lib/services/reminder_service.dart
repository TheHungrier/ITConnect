import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/activity_model.dart';
import '../models/my_activity_model.dart';

class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _enabledKey = 'reminder_enabled';
  static const String _minutesBeforeKey = 'reminder_minutes_before';

  static const String _channelId = 'itconnect_activity_reminders';
  static const String _channelName = 'Nhắc nhở hoạt động';
  static const String _channelDescription =
      'Thông báo nhắc sinh viên trước giờ hoạt động';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: initSettings);

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    final androidResult = await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final iosResult = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return androidResult ?? iosResult ?? true;
  }

  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);

    if (!value) {
      await cancelAllReminders();
    }
  }

  Future<int> getMinutesBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_minutesBeforeKey) ?? 60;
  }

  Future<void> setMinutesBefore(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_minutesBeforeKey, minutes);
  }

  Future<void> scheduleMyActivityReminder(
    MyActivityModel activity, {
    int? minutesBefore,
  }) async {
    await initialize();

    final enabled = await isReminderEnabled();

    if (!enabled) return;
    if (activity.status != 'upcoming') return;
    if (activity.attended) return;

    final safeMinutes = minutesBefore ?? await getMinutesBefore();
    final scheduledAt = activity.startAt.subtract(
      Duration(minutes: safeMinutes),
    );

    if (scheduledAt.isBefore(DateTime.now())) return;

    final notificationId = _notificationId(activity.activityId);

    await _notifications.zonedSchedule(
      id: notificationId,
      title: 'Sắp tới giờ hoạt động',
      body:
          '${activity.title} bắt đầu lúc ${_formatTime(activity.startAt)} tại ${activity.location}',
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: activity.activityId,
    );
  }

  Future<void> scheduleActivityReminderFromActivity(
    ActivityModel activity,
  ) async {
    await initialize();

    final enabled = await isReminderEnabled();

    if (!enabled) return;

    final minutesBefore = await getMinutesBefore();
    final scheduledAt = activity.startAt.subtract(
      Duration(minutes: minutesBefore),
    );

    if (scheduledAt.isBefore(DateTime.now())) return;

    final notificationId = _notificationId(activity.id);

    await _notifications.zonedSchedule(
      id: notificationId,
      title: 'Sắp tới giờ hoạt động',
      body:
          '${activity.title} bắt đầu lúc ${_formatTime(activity.startAt)} tại ${activity.location}',
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: activity.id,
    );
  }

  Future<void> scheduleAllMyActivityReminders(
    List<MyActivityModel> activities,
  ) async {
    final enabled = await isReminderEnabled();

    if (!enabled) return;

    final minutesBefore = await getMinutesBefore();

    for (final activity in activities) {
      await scheduleMyActivityReminder(activity, minutesBefore: minutesBefore);
    }
  }

  Future<void> cancelActivityReminder(String activityId) async {
    await initialize();
    await _notifications.cancel(id: _notificationId(activityId));
  }

  Future<void> cancelAllReminders() async {
    await initialize();
    await _notifications.cancelAll();
  }

  int _notificationId(String activityId) {
    var hash = 0;

    for (final codeUnit in activityId.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = hash ^ (hash >> 6);
    }

    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));

    return max(1, hash);
  }

  String _formatTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute ngày $day/$month';
  }
}
