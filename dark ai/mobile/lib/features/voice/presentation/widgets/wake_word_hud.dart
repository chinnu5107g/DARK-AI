import 'package:flutter/material.dart';
import '../../../../core/theme/dark_theme.dart';
import '../../chat/presentation/widgets/voice_visualizer.dart';
import '../models/voice_state.dart';
import '../wake_word_controller.dart';

class WakeWordHud extends StatelessWidget {
  final WakeWordController controller;

  const WakeWordHud({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final state = controller.state;
        if (state == VoiceState.idle) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DarkTheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getStateColor(state).withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _getStateColor(state).withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildStateIcon(state),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.label,
                          style: TextStyle(
                            color: _getStateColor(state),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (state == VoiceState.wakeWordListening) ...[
                          const Text(
                            'Hands-free & screen-off ready',
                            style: TextStyle(color: DarkTheme.textSecondary, fontSize: 11),
                          ),
                        ] else if (controller.currentPartialCommand.isNotEmpty) ...[
                          Text(
                            '"${controller.currentPartialCommand}"',
                            style: const TextStyle(
                              color: DarkTheme.textPrimary,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (state == VoiceState.listeningCommand || state == VoiceState.speaking) ...[
                    VoiceVisualizer(
                      isListening: state == VoiceState.listeningCommand,
                      isSpeaking: state == VoiceState.speaking,
                      color: _getStateColor(state),
                      barCount: 8,
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStateIcon(VoiceState state) {
    switch (state) {
      case VoiceState.wakeWordListening:
        return const Icon(Icons.radio_button_checked, color: DarkTheme.accentNeon, size: 18);
      case VoiceState.activated:
        return const Icon(Icons.bolt, color: Colors.amber, size: 20);
      case VoiceState.listeningCommand:
        return const Icon(Icons.mic, color: DarkTheme.primaryCyan, size: 20);
      case VoiceState.processing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: DarkTheme.primaryCyan),
        );
      case VoiceState.speaking:
        return const Icon(Icons.volume_up, color: DarkTheme.accentNeon, size: 20);
      case VoiceState.error:
        return const Icon(Icons.error_outline, color: DarkTheme.errorRed, size: 20);
      default:
        return const Icon(Icons.mic_off, color: DarkTheme.textSecondary, size: 18);
    }
  }

  Color _getStateColor(VoiceState state) {
    switch (state) {
      case VoiceState.wakeWordListening:
        return DarkTheme.accentNeon;
      case VoiceState.activated:
        return Colors.amber;
      case VoiceState.listeningCommand:
        return DarkTheme.primaryCyan;
      case VoiceState.processing:
        return DarkTheme.primaryCyan;
      case VoiceState.speaking:
        return DarkTheme.accentNeon;
      case VoiceState.error:
        return DarkTheme.errorRed;
      default:
        return DarkTheme.textSecondary;
    }
  }
}
