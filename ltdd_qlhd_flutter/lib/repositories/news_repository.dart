import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/news_model.dart';
import 'notification_repository.dart';

class NewsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<NewsModel>> getLatestNews() {
    return _db.collection('news').snapshots().map((snapshot) {
      final newsList = snapshot.docs
          .map((doc) => NewsModel.fromFirestore(doc))
          .toList();

      _sortNews(newsList);

      return newsList.take(5).toList();
    });
  }

  Stream<List<NewsModel>> getAllNews() {
    return _db.collection('news').snapshots().map((snapshot) {
      final newsList = snapshot.docs
          .map((doc) => NewsModel.fromFirestore(doc))
          .toList();

      _sortNews(newsList);

      return newsList;
    });
  }

  void _sortNews(List<NewsModel> newsList) {
    newsList.sort((a, b) {
      if (a.isImportant != b.isImportant) {
        return a.isImportant ? -1 : 1;
      }

      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });
  }

  Future<void> createNewsForAdmin({
    required String title,
    required String category,
    required String summary,
    required String content,
    String imageUrl = '',
    required bool isImportant,
  }) async {
    final safeTitle = title.trim();
    final safeCategory = category.trim().isEmpty ? 'Tin tức' : category.trim();
    final safeSummary = summary.trim();
    final safeContent = content.trim();
    final safeImageUrl = imageUrl.trim();

    if (safeTitle.isEmpty) {
      throw Exception('Tiêu đề tin tức không được để trống');
    }

    if (safeSummary.isEmpty) {
      throw Exception('Tóm tắt tin tức không được để trống');
    }

    final newsRef = _db.collection('news').doc();

    await newsRef.set({
      'title': safeTitle,
      'category': safeCategory,
      'summary': safeSummary,
      'content': safeContent,
      'imageUrl': safeImageUrl,
      'isImportant': isImportant,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (isImportant) {
      await NotificationRepository().createImportantNewsNotification(
        newsId: newsRef.id,
        newsTitle: safeTitle,
        summary: safeSummary,
      );
    }
  }

  Future<void> updateNewsForAdmin({
    required String newsId,
    required String title,
    required String category,
    required String summary,
    required String content,
    String imageUrl = '',
    required bool isImportant,
    required bool wasImportant,
  }) async {
    final safeNewsId = newsId.trim();
    final safeTitle = title.trim();
    final safeCategory = category.trim().isEmpty ? 'Tin tức' : category.trim();
    final safeSummary = summary.trim();
    final safeContent = content.trim();
    final safeImageUrl = imageUrl.trim();

    if (safeNewsId.isEmpty) {
      throw Exception('Mã tin tức không hợp lệ');
    }

    if (safeTitle.isEmpty) {
      throw Exception('Tiêu đề tin tức không được để trống');
    }

    if (safeSummary.isEmpty) {
      throw Exception('Tóm tắt tin tức không được để trống');
    }

    await _db.collection('news').doc(safeNewsId).set({
      'title': safeTitle,
      'category': safeCategory,
      'summary': safeSummary,
      'content': safeContent,
      'imageUrl': safeImageUrl,
      'isImportant': isImportant,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (isImportant && !wasImportant) {
      await NotificationRepository().createImportantNewsNotification(
        newsId: safeNewsId,
        newsTitle: safeTitle,
        summary: safeSummary,
      );
    }
  }

  Future<void> deleteNewsForAdmin(String newsId) async {
    final safeNewsId = newsId.trim();

    if (safeNewsId.isEmpty) {
      throw Exception('Mã tin tức không hợp lệ');
    }

    await _db.collection('news').doc(safeNewsId).delete();
  }
}
