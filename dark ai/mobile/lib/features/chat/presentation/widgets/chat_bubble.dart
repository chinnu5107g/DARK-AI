import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/dark_theme.dart';
import '../../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSpeakTap;

  const ChatBubble({
    Key? key,
    required this.message,
    this.onSpeakTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(left: 48, right: 12, top: 6, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF005F73), Color(0xFF0A9396)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: DarkTheme.primaryCyan.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isVoice) ...[
                  const Icon(Icons.mic, size: 12, color: DarkTheme.accentNeon),
                  const SizedBox(width: 4),
                ],
                Text(
                  timeStr,
                  style: const TextStyle(color: DarkTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Assistant bubble
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 48, top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: DarkTheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: message.isError
                    ? DarkTheme.errorRed.withOpacity(0.5)
                    : const Color(0xFF222F3E),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.intent != null && message.intent != 'general') ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DarkTheme.primaryCyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: DarkTheme.primaryCyan.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      message.intent!.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        color: DarkTheme.primaryCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.isError ? DarkTheme.errorRed : DarkTheme.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DARK AI • $timeStr',
                style: const TextStyle(color: DarkTheme.textSecondary, fontSize: 11),
              ),
              if (message.spokenText != null && onSpeakTap != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onSpeakTap,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.volume_up_outlined, size: 14, color: DarkTheme.primaryCyan),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
