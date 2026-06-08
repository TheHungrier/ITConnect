import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/news_model.dart';
import '../repositories/admin_news_repository.dart';

class AdminNewsController extends ChangeNotifier {
  final AdminNewsRepository _repository = AdminNewsRepository();
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  File? selectedImage;

  Stream<List<NewsModel>> getNews() {
    return _repository.getNews();
  }

  Future<void> pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    selectedImage = File(pickedFile.path);
    notifyListeners();
  }

  void clearSelectedImage() {
    selectedImage = null;
    notifyListeners();
  }

  Future<void> addNews({
    required String title,
    required String summary,
    required String content,
    required String category,
    required bool isImportant,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      String imageUrl = '';

      if (selectedImage != null) {
        imageUrl = await _repository.uploadNewsImage(selectedImage!);
      }

      final news = NewsModel(
        id: '',
        title: title.trim(),
        summary: summary.trim(),
        content: content.trim(),
        category: category.trim().isEmpty ? 'Tin tức' : category.trim(),
        imageUrl: imageUrl,
        isImportant: isImportant,
      );

      await _repository.addNews(news);

      selectedImage = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNews({
    required NewsModel oldNews,
    required String title,
    required String summary,
    required String content,
    required String category,
    required bool isImportant,
    bool removeOldImage = false,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      String imageUrl = removeOldImage ? '' : oldNews.imageUrl;

      if (selectedImage != null) {
        imageUrl = await _repository.uploadNewsImage(selectedImage!);
      }

      final newNews = NewsModel(
        id: oldNews.id,
        title: title.trim(),
        summary: summary.trim(),
        content: content.trim(),
        category: category.trim().isEmpty ? 'Tin tức' : category.trim(),
        imageUrl: imageUrl,
        isImportant: isImportant,
        createdAt: oldNews.createdAt,
        updatedAt: oldNews.updatedAt,
      );

      await _repository.updateNews(oldNews: oldNews, newNews: newNews);

      selectedImage = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNews(String newsId) async {
    await _repository.deleteNews(newsId);
  }
}
