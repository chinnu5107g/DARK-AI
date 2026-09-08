enum VoiceState {
  idle,
  wakeWordListening,
  activated,
  listeningCommand,
  processing,
  speaking,
  error,
}

extension VoiceStateExtension on VoiceState {
  static VoiceState fromString(String stateStr) {
    switch (stateStr.toUpperCase()) {
      case 'IDLE':
        return VoiceState.idle;
      case 'WAKE_WORD_LISTENING':
        return VoiceState.wakeWordListening;
      case 'ACTIVATED':
        return VoiceState.activated;
      case 'LISTENING_COMMAND':
        return VoiceState.listeningCommand;
      case 'PROCESSING':
        return VoiceState.processing;
      case 'SPEAKING':
        return VoiceState.speaking;
      case 'ERROR':
      default:
        return VoiceState.error;
    }
  }

  String get label {
    switch (this) {
      case VoiceState.idle:
        return 'Assistant Inactive';
      case VoiceState.wakeWordListening:
        return 'Listening for "Hey Dark"';
      case VoiceState.activated:
        return 'DARK Activated!';
      case VoiceState.listeningCommand:
        return 'Listening to your command...';
      case VoiceState.processing:
        return 'Processing with DARK AI...';
      case VoiceState.speaking:
        return 'DARK is speaking...';
      case VoiceState.error:
        return 'Voice Engine Error';
    }
  }

  bool get isActive => this != VoiceState.idle && this != VoiceState.error;
}
