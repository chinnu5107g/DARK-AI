import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../chat/controllers/chat_controller.dart';
import 'voice_service.dart';

class VoiceController extends ChangeNotifier {
  final VoiceService _voiceService;
  final ApiClient _apiClient;
  final ChatController _chatController;

  bool _isPushToTalkActive = false;
  bool get isPushToTalkActive => _isPushToTalkActive;

  double _audioLevel = 0.0;
  double get audioLevel => _audioLevel;

  Timer? _waveSimulationTimer;

  VoiceController({
    required VoiceService voiceService,
    required ApiClient apiClient,
    required ChatController chatController,
  })  : _voiceService = voiceService,
        _apiClient = apiClient,
        _chatController = chatController;

  void startPushToTalk() {
    _isPushToTalkActive = true;
    notifyListeners();

    // Start animated wave level generator
    _waveSimulationTimer?.cancel();
    _waveSimulationTimer = Timer.periodic(const Duration(milliseconds: 75), (timer) {
      _audioLevel = 0.2 + 0.8 * math.Random().nextDouble();
      notifyListeners();
    });
  }

  Future<void> finishPushToTalk(String commandText) async {
    _waveSimulationTimer?.cancel();
    _isPushToTalkActive = false;
    _audioLevel = 0.0;
    notifyListeners();

    if (commandText.trim().isEmpty) return;

    _chatController.addUserMessage(commandText, isVoice: true);

    try {
      final response = await _apiClient.processVoiceCommand(
        command: commandText,
        wakePhrase: "PTT",
        screenOff: false,
      );

      _chatController.addAssistantMessage(
        response.reply,
        spokenText: response.spokenText,
        intent: response.intent,
        isVoice: true,
      );

      if (response.spokenText.isNotEmpty) {
        await _voiceService.speak(response.spokenText);
      }
    } catch (e) {
      _chatController.addErrorMessage("Voice command error: $e");
    }
  }

  void cancelPushToTalk() {
    _waveSimulationTimer?.cancel();
    _isPushToTalkActive = false;
    _audioLevel = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _waveSimulationTimer?.cancel();
    super.dispose();
  }
}
