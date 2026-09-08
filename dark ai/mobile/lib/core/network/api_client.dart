import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiResponse {
  final bool isSuccess;
  final String reply;
  final String spokenText;
  final String intent;
  final Map<String, dynamic>? actionData;
  final String? errorMessage;

  ApiResponse({
    required this.isSuccess,
    required this.reply,
    required this.spokenText,
    this.intent = 'general',
    this.actionData,
    this.errorMessage,
  });

  factory ApiResponse.success(Map<String, dynamic> json) {
    return ApiResponse(
      isSuccess: true,
      reply: json['reply'] ?? '',
      spokenText: json['spoken_text'] ?? json['reply'] ?? '',
      intent: json['intent'] ?? 'general',
      actionData: json['action_data'] as Map<String, dynamic>?,
    );
  }

  factory ApiResponse.failure(String error) {
    return ApiResponse(
      isSuccess: false,
      reply: '⚠️ Unable to reach DARK backend: $error',
      spokenText: 'I cannot connect to the server at this moment.',
      errorMessage: error,
    );
  }
}

class ApiClient {
  String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? AppConstants.defaultBackendUrl;

  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl.replaceAll(RegExp(r'/$'), ''); // strip trailing slash
  }

  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/api/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      log('Healthcheck failed: $e');
      return false;
    }
  }

  Future<ApiResponse> sendChatMessage({
    required String message,
    String source = 'text',
    bool screenOff = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/chat');
      final body = jsonEncode({
        'message': message,
        'source': source,
        'screen_off': screenOff,
        'session_id': 'mobile_session',
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        return ApiResponse.failure('Server returned error ${response.statusCode}');
      }
    } catch (e) {
      log('API Chat request exception: $e');
      // Offline fallback: provide helpful on-device response
      return _generateOfflineFallback(message);
    }
  }

  Future<ApiResponse> processVoiceCommand({
    required String command,
    String wakePhrase = 'Hey Dark',
    bool screenOff = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/voice/process');
      final body = jsonEncode({
        'command': command,
        'wake_phrase': wakePhrase,
        'confidence': 1.0,
        'screen_off': screenOff,
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(data);
      } else {
        return ApiResponse.failure('Voice processing error: ${response.statusCode}');
      }
    } catch (e) {
      log('Voice processing network exception: $e');
      return _generateOfflineFallback(command);
    }
  }

  ApiResponse _generateOfflineFallback(String command) {
    final lower = command.toLowerCase().trim();
    if (lower.contains('time')) {
      final now = DateTime.now();
      final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
      return ApiResponse(
        isSuccess: true,
        reply: '🕒 Current time (On-device): **$timeStr**',
        spokenText: 'The time is $timeStr.',
        intent: 'time_query',
      );
    }

    return ApiResponse(
      isSuccess: true,
      reply: '🤖 DARK processed: "$command"\n*(Offline mode - connecting to backend...)*',
      spokenText: 'I heard: $command. Standing by.',
      intent: 'offline_ack',
    );
  }
}
