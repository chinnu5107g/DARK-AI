class AppConstants {
  static const String appName = 'DARK AI';
  static const String appTagline = 'Personal Assistant & Voice Activation';
  
  // Platform Channels
  static const String methodChannel = 'com.dark.ai/assistant';
  static const String eventChannel = 'com.dark.ai/assistant_events';
  
  // Default Backend
  static const String defaultBackendUrl = 'http://10.0.2.2:8000'; // Standard Android emulator localhost loopback
  
  // Default Wake Phrase
  static const String defaultWakePhrase = 'Hey Dark';
  
  // Preferences Keys
  static const String prefWakeWordEnabled = 'pref_wake_word_enabled';
  static const String prefWakePhrase = 'pref_wake_phrase';
  static const String prefVoiceResponseEnabled = 'pref_voice_response_enabled';
  static const String prefBackgroundModeEnabled = 'pref_background_mode_enabled';
  static const String prefBackendUrl = 'pref_backend_url';
}
