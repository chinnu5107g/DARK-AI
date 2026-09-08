import 'dart:developer';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/chat_message.dart';
import '../../voice/voice_service.dart';

class ChatController extends ChangeNotifier {
  final ApiClient _apiClient;
  final VoiceService _voiceService;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  ChatController({
    required ApiClient apiClient,
    required VoiceService voiceService,
  })  : _apiClient = apiClient,
        _voiceService = voiceService {
    // Add introductory message
    _messages.add(
      ChatMessage.assistant(
        "👋 Greetings. I am **DARK**, your autonomous AI assistant.\n\n"
        "• Wake me anytime by saying **\"Hey Dark\"**, even when the screen is off.\n"
        "• Or tap the microphone below for push-to-talk voice input.",
        spokenText: "Greetings. I am DARK, your autonomous assistant. Say Hey Dark anytime to wake me.",
      ),
    );
  }

  void addUserMessage(String text, {bool isVoice = false}) {
    _messages.add(ChatMessage.user(text, isVoice: isVoice));
    notifyListeners();
  }

  void addAssistantMessage(String text, {String? spokenText, String? intent, bool isVoice = false}) {
    _messages.add(ChatMessage.assistant(
      text,
      spokenText: spokenText,
      intent: intent,
      isVoice: isVoice,
    ));
    notifyListeners();
  }

  void addErrorMessage(String text) {
    _messages.add(ChatMessage.error(text));
    notifyListeners();
  }

  Future<void> sendTextMessage(String text, {bool speakResponse = false}) async {
    if (text.trim().isEmpty || _isProcessing) return;

    addUserMessage(text.trim(), isVoice: false);
    _isProcessing = true;
    notifyListeners();

    try {
      final response = await _apiClient.sendChatMessage(
        message: text.trim(),
        source: 'text',
      );

      _isProcessing = false;
      addAssistantMessage(
        response.reply,
        spokenText: response.spokenText,
        intent: response.intent,
      );

      if (speakResponse && response.spokenText.isNotEmpty) {
        await _voiceService.speak(response.spokenText);
      }
    } catch (e) {
      log('Error sending text message: $e');
      _isProcessing = false;
      addErrorMessage('Error communicating with DARK backend: $e');
    }
  }

  void clearMessages() {
    _messages.clear();
    _messages.add(
      ChatMessage.assistant("Conversation cleared. Ready for your next command."),
    );
    notifyListeners();
  }
}
