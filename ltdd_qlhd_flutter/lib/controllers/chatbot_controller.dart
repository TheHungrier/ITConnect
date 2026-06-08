import 'package:flutter/material.dart';

import '../models/chat_message_model.dart';
import '../repositories/chatbot_repository.dart';

class ChatbotController extends ChangeNotifier {
  final ChatbotRepository _repository = ChatbotRepository();

  final List<ChatMessageModel> messages = [
    ChatMessageModel.bot(
      'Xin chào! Mình là trợ lý ITConnect. Bạn có thể hỏi về hoạt động, điểm rèn luyện, điểm danh, bản đồ hoặc góp ý.',
    ),
  ];

  bool isSending = false;

  Future<void> sendMessage(String text) async {
    final message = text.trim();

    if (message.isEmpty) return;
    if (isSending) return;

    messages.add(ChatMessageModel.user(message));
    isSending = true;
    notifyListeners();

    try {
      final reply = await _repository.sendMessage(message);
      messages.add(ChatMessageModel.bot(reply));
    } catch (e) {
      messages.add(
        ChatMessageModel.bot(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
