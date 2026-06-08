import 'package:flutter/material.dart';

import '../models/my_activity_model.dart';
import '../models/term_model.dart';
import '../repositories/my_activity_repository.dart';
import '../repositories/term_repository.dart';

class MyActivityController extends ChangeNotifier {
  final MyActivityRepository _myActivityRepository = MyActivityRepository();
  final TermRepository _termRepository = TermRepository();

  int tab = 0;
  String selectedTermId = '';

  Stream<List<MyActivityModel>> getMyActivities() {
    return _myActivityRepository.getMyActivities();
  }

  Stream<List<TermModel>> getTerms() {
    return _termRepository.getTerms();
  }

  void ensureSelectedTerm(List<TermModel> terms) {
    if (terms.isEmpty) return;

    final exists = terms.any((term) => term.id == selectedTermId);

    if (selectedTermId.trim().isEmpty || !exists) {
      selectedTermId = terms.first.id;
    }
  }

  void changeTab(int index) {
    tab = index;
    notifyListeners();
  }

  void changeTerm(String termId) {
    selectedTermId = termId;
    tab = 0;
    notifyListeners();
  }

  String selectedTermName(List<TermModel> terms) {
    if (terms.isEmpty) return 'Chưa có học kỳ';

    final term = terms.firstWhere(
      (term) => term.id == selectedTermId,
      orElse: () => terms.first,
    );

    return term.name;
  }

  List<MyActivityModel> activitiesBySelectedTerm(
    List<MyActivityModel> activities,
  ) {
    return activities
        .where((a) => a.termId == selectedTermId && a.status != 'cancelled')
        .toList();
  }

  bool isUpcoming(MyActivityModel activity) {
    final now = DateTime.now();
    final status = activity.status;

    if (status == 'cancelled') return false;
    if (status == 'pending_review') return false;
    if (status == 'absent') return false;
    if (status == 'missed') return false;
    if (status == 'not_completed') return false;
    if (activity.attended) return false;
    if (status == 'completed') return false;

    return status == 'upcoming' && activity.endAt.isAfter(now);
  }

  bool isUnfinished(MyActivityModel activity) {
    final now = DateTime.now();
    final status = activity.status;

    if (status == 'cancelled') return false;
    if (activity.attended && status == 'completed') return false;

    if (status == 'pending_review') return true;
    if (status == 'absent') return true;
    if (status == 'missed') return true;
    if (status == 'not_completed') return true;

    if (status == 'completed' && !activity.attended) return true;

    return status == 'upcoming' && activity.endAt.isBefore(now);
  }

  bool isCompleted(MyActivityModel activity) {
    final status = activity.status;

    if (status == 'cancelled') return false;

    return status == 'completed' && activity.attended;
  }

  List<MyActivityModel> filterActivities(List<MyActivityModel> activities) {
    final termActivities = activitiesBySelectedTerm(activities);

    if (tab == 0) {
      return termActivities.where(isUpcoming).toList();
    }

    if (tab == 1) {
      return termActivities.where(isUnfinished).toList();
    }

    return termActivities.where(isCompleted).toList();
  }

  int activityPoints(List<MyActivityModel> activities) {
    final termActivities = activitiesBySelectedTerm(activities);

    return termActivities.where(isCompleted).fold(0, (sum, activity) {
      return sum + activity.points;
    });
  }

  int penaltyPoints(List<MyActivityModel> activities) {
    final termActivities = activitiesBySelectedTerm(activities);

    return termActivities
        .where((activity) {
          return activity.status == 'absent' || activity.penaltyPoints > 0;
        })
        .fold(0, (sum, activity) {
          final penalty = activity.penaltyPoints > 0
              ? activity.penaltyPoints
              : 6;
          return sum + penalty;
        });
  }

  int trainingPoints(List<MyActivityModel> activities) {
    final total = 70 + activityPoints(activities) - penaltyPoints(activities);

    if (total > 100) return 100;
    if (total < 0) return 0;

    return total;
  }

  String trainingRank(List<MyActivityModel> activities) {
    final points = trainingPoints(activities);

    if (points >= 90) return 'Xuất sắc';
    if (points >= 80) return 'Tốt';
    if (points >= 65) return 'Khá';
    if (points >= 50) return 'Trung bình';
    if (points >= 35) return 'Yếu';

    return 'Kém';
  }

  int completedCount(List<MyActivityModel> activities) {
    final termActivities = activitiesBySelectedTerm(activities);

    return termActivities.where(isCompleted).length;
  }

  int upcomingCount(List<MyActivityModel> activities) {
    final termActivities = activitiesBySelectedTerm(activities);

    return termActivities.where(isUpcoming).length;
  }

  int unfinishedCount(List<MyActivityModel> activities) {
    final termActivities = activitiesBySelectedTerm(activities);

    return termActivities.where(isUnfinished).length;
  }

  int absentCount(List<MyActivityModel> activities) {
    final termActivities = activitiesBySelectedTerm(activities);

    return termActivities.where((activity) {
      return activity.status == 'absent';
    }).length;
  }

  double pointProgress(List<MyActivityModel> activities) {
    return trainingPoints(activities) / 100;
  }
}
