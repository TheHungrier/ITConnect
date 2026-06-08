class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  factory ChatMessageModel.user(String text) {
    return ChatMessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      createdAt: DateTime.now(),
    );
  }

  factory ChatMessageModel.bot(String text) {
    return ChatMessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      createdAt: DateTime.now(),
    );
  }
}
