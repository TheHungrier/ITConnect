import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/news_model.dart';
import '../services/cloudinary_service.dart';
import 'notification_repository.dart';

class AdminNewsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<NewsModel>> getNews() {
    return _db.collection('news').snapshots().map((snapshot) {
      final newsList = snapshot.docs
          .map((doc) => NewsModel.fromFirestore(doc))
          .toList();

      newsList.sort((a, b) {
        if (a.isImportant != b.isImportant) {
          return a.isImportant ? -1 : 1;
        }

        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return newsList;
    });
  }

  Future<String> uploadNewsImage(File imageFile) async {
    return CloudinaryService.instance.uploadNewsImage(imageFile);
  }

  Future<void> addNews(NewsModel news) async {
    final newsRef = _db.collection('news').doc();

    await newsRef.set(news.toCreateMap());

    if (news.isImportant) {
      await NotificationRepository().createImportantNewsNotification(
        newsId: newsRef.id,
        newsTitle: news.title,
        summary: news.summary,
      );
    }
  }

  Future<void> updateNews({
    required NewsModel oldNews,
    required NewsModel newNews,
  }) async {
    await _db.collection('news').doc(oldNews.id).update(newNews.toUpdateMap());

    if (newNews.isImportant && !oldNews.isImportant) {
      await NotificationRepository().createImportantNewsNotification(
        newsId: oldNews.id,
        newsTitle: newNews.title,
        summary: newNews.summary,
      );
    }
  }

  Future<void> deleteNews(String newsId) async {
    await _db.collection('news').doc(newsId).delete();
  }
}
