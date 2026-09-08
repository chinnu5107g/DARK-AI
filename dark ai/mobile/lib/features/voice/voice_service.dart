import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';

class VoiceService {
  static const MethodChannel _methodChannel = MethodChannel(AppConstants.methodChannel);
  static const EventChannel _eventChannel = EventChannel(AppConstants.eventChannel);

  Stream<Map<String, dynamic>>? _eventsStream;

  Stream<Map<String, dynamic>> get events {
    _eventsStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => Map<String, dynamic>.from(event as Map));
    return _eventsStream!;
  }

  /// Start the native Kotlin foreground service and wake-word listener.
  Future<bool> startWakeWordService({String wakePhrase = 'Hey Dark'}) async {
    try {
      final bool? success = await _methodChannel.invokeMethod<bool>(
        'startWakeWordService',
        {'wakePhrase': wakePhrase},
      );
      return success ?? false;
    } on PlatformException catch (e) {
      log('PlatformException starting WakeWordService: ${e.message}');
      return false;
    } catch (e) {
      log('Exception starting WakeWordService: $e');
      return false;
    }
  }

  /// Stop the native foreground service and release all audio/wakelock resources.
  Future<bool> stopWakeWordService() async {
    try {
      final bool? success = await _methodChannel.invokeMethod<bool>('stopWakeWordService');
      return success ?? false;
    } on PlatformException catch (e) {
      log('PlatformException stopping WakeWordService: ${e.message}');
      return false;
    } catch (e) {
      log('Exception stopping WakeWordService: $e');
      return false;
    }
  }

  /// Query native foreground service running state.
  Future<bool> isServiceRunning() async {
    try {
      final Map<dynamic, dynamic>? status =
          await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getWakeWordStatus');
      return status?['isRunning'] == true;
    } catch (e) {
      log('Error querying wake word status: $e');
      return false;
    }
  }

  /// Trigger native Android Text-to-Speech playback.
  Future<bool> speak(String text) async {
    try {
      final bool? success = await _methodChannel.invokeMethod<bool>(
        'speak',
        {'text': text},
      );
      return success ?? false;
    } catch (e) {
      log('Error invoking speak: $e');
      return false;
    }
  }

  /// Check whether battery optimization is exempted for this app.
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final bool? isIgnored =
          await _methodChannel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return isIgnored ?? false;
    } catch (e) {
      log('Error checking battery optimization: $e');
      return false;
    }
  }

  /// Request battery optimization exemption from Android system.
  Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final bool? result =
          await _methodChannel.invokeMethod<bool>('requestBatteryOptimizationExemption');
      return result ?? false;
    } catch (e) {
      log('Error requesting battery optimization exemption: $e');
      return false;
    }
  }
}
