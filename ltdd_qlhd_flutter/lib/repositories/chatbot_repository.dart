import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ChatbotRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Khi test local FastAPI trên Android emulator dùng 10.0.2.2.
  // Khi chạy điện thoại thật, thay bằng IP máy tính cùng Wi-Fi, ví dụ: http://192.168.1.5:8000
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<String> sendMessage(String message) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Bạn cần đăng nhập để sử dụng chatbot');
    }

    final idToken = await user.getIdToken();

    final uri = Uri.parse('$baseUrl/chat');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({'userId': user.uid, 'message': message.trim()}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMessage = 'Chatbot không phản hồi. Vui lòng thử lại';

      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        errorMessage = data['detail']?.toString() ?? errorMessage;
      } catch (_) {}

      throw Exception(errorMessage);
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final reply = data['reply']?.toString() ?? '';

    if (reply.trim().isEmpty) {
      throw Exception('Chatbot chưa có câu trả lời phù hợp');
    }
    return reply;
  }
}
