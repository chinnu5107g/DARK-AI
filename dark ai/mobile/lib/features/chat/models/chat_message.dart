class ChatMessage {
  final String id;
  final String text;
  final String? spokenText;
  final bool isUser;
  final DateTime timestamp;
  final String? intent;
  final bool isVoice;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.text,
    this.spokenText,
    required this.isUser,
    required this.timestamp,
    this.intent,
    this.isVoice = false,
    this.isError = false,
  });

  factory ChatMessage.user(String text, {bool isVoice = false}) {
    return ChatMessage(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      isVoice: isVoice,
    );
  }

  factory ChatMessage.assistant(String text, {String? spokenText, String? intent, bool isVoice = false}) {
    return ChatMessage(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      spokenText: spokenText,
      isUser: false,
      timestamp: DateTime.now(),
      intent: intent,
      isVoice: isVoice,
    );
  }

  factory ChatMessage.error(String text) {
    return ChatMessage(
      id: 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );
  }
}
