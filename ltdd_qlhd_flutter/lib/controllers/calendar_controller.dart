import 'package:flutter/material.dart';

import '../models/activity_model.dart';
import '../repositories/activity_repository.dart';

class CalendarController extends ChangeNotifier {
  final ActivityRepository _activityRepository = ActivityRepository();

  DateTime selectedDate = DateTime.now();
  String viewMode = 'month';

  Stream<List<ActivityModel>> getAllActivities() {
    return _activityRepository.getAllActivities();
  }

  DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  List<ActivityModel> activitiesOfDay(
    List<ActivityModel> activities,
    DateTime date,
  ) {
    return activities.where((activity) {
      return isSameDay(activity.startAt, date);
    }).toList();
  }

  List<ActivityModel> activitiesOfMonth(
    List<ActivityModel> activities,
    DateTime date,
  ) {
    return activities.where((activity) {
      return isSameMonth(activity.startAt, date);
    }).toList();
  }

  List<DateTime> daysOfCurrentWeek() {
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    return List.generate(
      7,
      (index) => dateOnly(startOfWeek.add(Duration(days: index))),
    );
  }

  List<DateTime> daysOfCurrentMonth() {
    final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    final leadingEmptyDays = firstDay.weekday - 1;
    final totalDays = leadingEmptyDays + lastDay.day;
    final totalCells =
        totalDays % 7 == 0 ? totalDays : totalDays + (7 - totalDays % 7);

    return List.generate(totalCells, (index) {
      final dayNumber = index - leadingEmptyDays + 1;
      return DateTime(selectedDate.year, selectedDate.month, dayNumber);
    });
  }

  String monthTitle(DateTime date) {
    return 'Tháng ${date.month}, ${date.year}';
  }

  String dayTitle(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String headerTitle() {
    if (viewMode == 'day') {
      return dayTitle(selectedDate);
    }

    if (viewMode == 'week') {
      final week = daysOfCurrentWeek();
      return '${dayTitle(week.first)} - ${dayTitle(week.last)}';
    }

    return monthTitle(selectedDate);
  }

  void previous() {
    if (viewMode == 'day') {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    } else if (viewMode == 'week') {
      selectedDate = selectedDate.subtract(const Duration(days: 7));
    } else {
      selectedDate = DateTime(
        selectedDate.year,
        selectedDate.month - 1,
        1,
      );
    }

    notifyListeners();
  }

  void next() {
    if (viewMode == 'day') {
      selectedDate = selectedDate.add(const Duration(days: 1));
    } else if (viewMode == 'week') {
      selectedDate = selectedDate.add(const Duration(days: 7));
    } else {
      selectedDate = DateTime(
        selectedDate.year,
        selectedDate.month + 1,
        1,
      );
    }

    notifyListeners();
  }

  void goToday() {
    selectedDate = DateTime.now();
    notifyListeners();
  }

  void changeViewMode(String mode) {
    viewMode = mode;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }
}