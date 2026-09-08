import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../voice/voice_service.dart';
import '../../voice/wake_word_controller.dart';

class SettingsController extends ChangeNotifier {
  final VoiceService _voiceService;
  final ApiClient _apiClient;
  final WakeWordController _wakeWordController;

  bool _micPermissionGranted = false;
  bool get micPermissionGranted => _micPermissionGranted;

  bool _notificationPermissionGranted = false;
  bool get notificationPermissionGranted => _notificationPermissionGranted;

  bool _batteryOptimizationIgnored = false;
  bool get batteryOptimizationIgnored => _batteryOptimizationIgnored;

  String _backendUrl = AppConstants.defaultBackendUrl;
  String get backendUrl => _backendUrl;

  bool _backgroundModeEnabled = true;
  bool get backgroundModeEnabled => _backgroundModeEnabled;

  SettingsController({
    required VoiceService voiceService,
    required ApiClient apiClient,
    required WakeWordController wakeWordController,
  })  : _voiceService = voiceService,
        _apiClient = apiClient,
        _wakeWordController = wakeWordController {
    refreshAll();
  }

  Future<void> refreshAll() async {
    await checkPermissions();
    await checkBatteryStatus();
    await loadSettings();
    notifyListeners();
  }

  Future<void> checkPermissions() async {
    final micStatus = await Permission.microphone.status;
    _micPermissionGranted = micStatus.isGranted;

    final notifStatus = await Permission.notification.status;
    _notificationPermissionGranted = notifStatus.isGranted;

    notifyListeners();
  }

  Future<void> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    _micPermissionGranted = status.isGranted;
    notifyListeners();
  }

  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    _notificationPermissionGranted = status.isGranted;
    notifyListeners();
  }

  Future<void> checkBatteryStatus() async {
    _batteryOptimizationIgnored = await _voiceService.isBatteryOptimizationIgnored();
    notifyListeners();
  }

  Future<void> requestBatteryOptimization() async {
    await _voiceService.requestBatteryOptimizationExemption();
    // Recheck after returning
    Future.delayed(const Duration(seconds: 1), () async {
      await checkBatteryStatus();
    });
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _backendUrl = prefs.getString(AppConstants.prefBackendUrl) ?? AppConstants.defaultBackendUrl;
    _backgroundModeEnabled = prefs.getBool(AppConstants.prefBackgroundModeEnabled) ?? true;
    _apiClient.updateBaseUrl(_backendUrl);
    notifyListeners();
  }

  Future<void> setBackendUrl(String url) async {
    _backendUrl = url;
    _apiClient.updateBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefBackendUrl, url);
    notifyListeners();
  }

  Future<void> setBackgroundModeEnabled(bool enabled) async {
    _backgroundModeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefBackgroundModeEnabled, enabled);
    notifyListeners();
  }

  Future<bool> toggleWakeWord(bool enable) async {
    // If enabling, ensure permissions are granted
    if (enable) {
      if (!_micPermissionGranted) {
        await requestMicrophonePermission();
        if (!_micPermissionGranted) {
          log('Cannot enable wake word: microphone permission denied.');
          return false;
        }
      }

      if (!_notificationPermissionGranted) {
        await requestNotificationPermission();
      }
    }

    final success = await _wakeWordController.toggleWakeWordService(enable);
    notifyListeners();
    return success;
  }
}
