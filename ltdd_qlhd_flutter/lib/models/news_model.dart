import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String category;
  final String imageUrl;
  final bool isImportant;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.category,
    required this.imageUrl,
    required this.isImportant,
    this.createdAt,
    this.updatedAt,
  });

  factory NewsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return NewsModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      summary: data['summary']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Tin tức',
      imageUrl: data['imageUrl']?.toString() ?? '',
      isImportant: data['isImportant'] == true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'isImportant': isImportant,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'isImportant': isImportant,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
