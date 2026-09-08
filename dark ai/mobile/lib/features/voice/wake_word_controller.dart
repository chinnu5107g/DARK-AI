import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../chat/controllers/chat_controller.dart';
import 'models/voice_state.dart';
import 'voice_service.dart';

class WakeWordController extends ChangeNotifier {
  final VoiceService _voiceService;
  final ApiClient _apiClient;
  ChatController? chatController;

  StreamSubscription<Map<String, dynamic>>? _eventsSub;

  VoiceState _state = VoiceState.idle;
  VoiceState get state => _state;

  bool _isWakeWordEnabled = false;
  bool get isWakeWordEnabled => _isWakeWordEnabled;

  bool _voiceResponseEnabled = true;
  bool get voiceResponseEnabled => _voiceResponseEnabled;

  String _wakePhrase = AppConstants.defaultWakePhrase;
  String get wakePhrase => _wakePhrase;

  String _currentPartialCommand = '';
  String get currentPartialCommand => _currentPartialCommand;

  String _lastErrorMessage = '';
  String get lastErrorMessage => _lastErrorMessage;

  WakeWordController({
    required VoiceService voiceService,
    required ApiClient apiClient,
    this.chatController,
  })  : _voiceService = voiceService,
        _apiClient = apiClient {
    _initSettings();
    _subscribeToNativeEvents();
  }

  Future<void> _initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isWakeWordEnabled = prefs.getBool(AppConstants.prefWakeWordEnabled) ?? false;
    _wakePhrase = prefs.getString(AppConstants.prefWakePhrase) ?? AppConstants.defaultWakePhrase;
    _voiceResponseEnabled = prefs.getBool(AppConstants.prefVoiceResponseEnabled) ?? true;
    notifyListeners();

    // If previously enabled, resume service
    if (_isWakeWordEnabled) {
      startService();
    }
  }

  void _subscribeToNativeEvents() {
    _eventsSub?.cancel();
    _eventsSub = _voiceService.events.listen(
      _handleNativeEvent,
      onError: (err) {
        log('Error on native event stream: $err');
        _state = VoiceState.error;
        _lastErrorMessage = err.toString();
        notifyListeners();
      },
    );
  }

  void _handleNativeEvent(Map<String, dynamic> data) {
    final String eventType = data['event'] ?? '';
    log('Native event received: $eventType -> $data');

    switch (eventType) {
      case 'state_changed':
        final stateStr = data['state'] as String? ?? 'IDLE';
        _state = VoiceStateExtension.fromString(stateStr);
        notifyListeners();
        break;

      case 'wake_word_detected':
        _state = VoiceState.activated;
        _currentPartialCommand = '';
        notifyListeners();
        break;

      case 'listening_started':
        _state = VoiceState.listeningCommand;
        _currentPartialCommand = '';
        notifyListeners();
        break;

      case 'command_partial':
        _currentPartialCommand = data['text'] ?? '';
        notifyListeners();
        break;

      case 'command_received':
        final command = data['text'] as String? ?? '';
        final screenOff = data['screen_off'] as bool? ?? false;
        _currentPartialCommand = '';
        _processCommand(command, screenOff);
        break;

      case 'speaking_started':
        _state = VoiceState.speaking;
        notifyListeners();
        break;

      case 'speaking_finished':
        // Service automatically resumes WAKE_WORD_LISTENING
        _state = VoiceState.wakeWordListening;
        notifyListeners();
        break;

      case 'service_error':
        _lastErrorMessage = data['message'] ?? 'Unknown voice error';
        _state = VoiceState.error;
        notifyListeners();
        break;
    }
  }

  Future<void> _processCommand(String command, bool screenOff) async {
    if (command.trim().isEmpty) return;

    _state = VoiceState.processing;
    notifyListeners();

    // Add user voice command to chat stream
    chatController?.addUserMessage(command, isVoice: true);

    try {
      final response = await _apiClient.processVoiceCommand(
        command: command,
        wakePhrase: _wakePhrase,
        screenOff: screenOff,
      );

      // Add assistant response to chat stream
      chatController?.addAssistantMessage(
        response.reply,
        spokenText: response.spokenText,
        intent: response.intent,
        isVoice: true,
      );

      // Speak response if enabled
      if (_voiceResponseEnabled && response.spokenText.isNotEmpty) {
        _state = VoiceState.speaking;
        notifyListeners();
        await _voiceService.speak(response.spokenText);
      }
    } catch (e) {
      log('Error handling command: $e');
      chatController?.addErrorMessage('Failed to process command: $e');
      _state = VoiceState.error;
      notifyListeners();
    }
  }

  Future<bool> toggleWakeWordService(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    if (enable) {
      final success = await startService();
      if (success) {
        _isWakeWordEnabled = true;
        await prefs.setBool(AppConstants.prefWakeWordEnabled, true);
        notifyListeners();
        return true;
      }
      return false;
    } else {
      final success = await stopService();
      _isWakeWordEnabled = false;
      await prefs.setBool(AppConstants.prefWakeWordEnabled, false);
      notifyListeners();
      return success;
    }
  }

  Future<bool> startService() async {
    final success = await _voiceService.startWakeWordService(wakePhrase: _wakePhrase);
    if (success) {
      _state = VoiceState.wakeWordListening;
      _isWakeWordEnabled = true;
      notifyListeners();
    }
    return success;
  }

  Future<bool> stopService() async {
    final success = await _voiceService.stopWakeWordService();
    _state = VoiceState.idle;
    _isWakeWordEnabled = false;
    notifyListeners();
    return success;
  }

  void setWakePhrase(String phrase) async {
    _wakePhrase = phrase;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefWakePhrase, phrase);
    if (_isWakeWordEnabled) {
      // Restart with new phrase
      await startService();
    }
    notifyListeners();
  }

  void setVoiceResponseEnabled(bool enabled) async {
    _voiceResponseEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefVoiceResponseEnabled, enabled);
    notifyListeners();
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }
}
